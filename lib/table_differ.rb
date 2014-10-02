# Copyright 2014 Scott Bronson
# Licensed under pain-free MIT. See LICENSE.txt.

require "active_support/concern"
require "active_record"


module TableDiffer
  extend ActiveSupport::Concern

  included do
    attr_accessor :original_attributes
  end

  module ClassMethods
    # pass a date or name fragment, receive the full snapshot name.
    # it's ok to pass a snapshot name; it will be returned unchaged.
    def snapshot_name name
      return nil if name.nil?

      if name.kind_of?(Date) || name.kind_of?(Time)
        name = name.strftime("%Y%m%d_%H%M%S")
      end

      unless name.index(table_name) == 0
        name = "#{table_name}_#{name}"
      end

      name
    end

    # returns an array of the snapshot names that currently exist
    def snapshots
      connection.tables.grep(/^#{table_name}_/).sort
    end

    # creates a new snapshot
    def create_snapshot suggestion=Time.now
      name = snapshot_name(suggestion)
      connection.execute("CREATE TABLE #{name} AS SELECT * FROM #{table_name}")
      name
    end

    def restore_snapshot name
      name = snapshot_name(name)
      raise "#{name} doesn't exist" unless connection.tables.include?(name)

      delete_all
      connection.execute("INSERT INTO #{table_name} SELECT * FROM #{name}")
    end

    # deletes the named snapshot
    def delete_snapshot name
      connection.execute("DROP TABLE #{snapshot_name(name)}")
    end

    # deletes every snapshot named in the array
    # Model.delete_snapshots(:all) deletes all snapshots
    def delete_snapshots snaps=self.snapshots, &block
      snaps = snaps.select(&block) if block
      snaps.each { |name| delete_snapshot(name) }
    end

    def table_differ_remap_objects params, records, table
      model = self
      if table != table_name
        # create an exact copy of the model, but using a different table
        model = Class.new(self)
        model.table_name = table
      end

      params = Array(params)
      records.map do |record|
        result = record
        if record.id.nil?   # don't look up real ActiveRecord object if we already have one
          args = params.inject({}) { |hash,key| hash[key] = record[key]; hash }
          real_record = model.where(args).first
          if real_record
            if model != self
              real_record = self.new(real_record.attributes)  # convert fake model to real model
            end
            real_record.original_attributes = record.attributes
            result = real_record
          end
        end
        result
      end
    end

    def diff_snapshot options={}
      oldtable = snapshot_name(options[:old]) || snapshots.last
      newtable = snapshot_name(options[:new]) || table_name

      ignore = []
      if options[:ignore]
        ignore = Array(options[:ignore]).map(&:to_s)
      end

      columns = column_names - ignore
      cols = columns.map { |c| "#{c} as #{c}" }.join(", ")

      added =   find_by_sql("SELECT #{cols} FROM #{newtable} EXCEPT SELECT #{cols} FROM #{oldtable}")
      removed = find_by_sql("SELECT #{cols} from #{oldtable} EXCEPT SELECT #{cols} FROM #{newtable}")

      # hm, none of this seems to matter...  TODO: mark appropriate objects read-only: obj.readonly!
      # AR always thinks the record is persisted in the db, even when it obviously isn't
      # added.each   { |o| o.instance_variable_set("@new_record", true) } unless table_name == oldtable
      # removed.each { |o| o.instance_variable_set("@new_record", true) } unless table_name == newtable
      # actually, it's probably more reliable just to use the presence of an id to determine if the record can be saved
      # [*added, *removed].select { |o| !o.id }.each { |o| o.instance_variable_set("@new_record", true) }

      if options[:unique_by]
        added = table_differ_remap_objects(options[:unique_by], added, newtable)
        removed = table_differ_remap_objects(options[:unique_by], removed, oldtable)
      end

      changed = added & removed
      changed.each do |obj|
        orig = removed.find { |r| r == obj }
        raise "this is impossible" if orig.nil?
        obj.original_attributes = (orig.original_attributes || orig.attributes).except(*ignore)
      end

      added -= changed
      removed -= changed
      [*added, *removed].each { |o| o.original_attributes = nil }

      [added, removed, changed]
    end
  end
end
