require "active_support/concern"
require "active_record"


module TableDiffer
  extend ActiveSupport::Concern

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
    def create_snapshot name=Time.now
      connection.execute("CREATE TABLE #{snapshot_name(name)} AS SELECT * FROM #{table_name}")
    end

    # deletes the named snapshot
    def delete_snapshot name
      connection.execute("DROP TABLE #{snapshot_name(name)}")
    end

    # deletes every snapshot named in the array
    def delete_snapshots snapshots
      snapshots.each { |name| delete_snapshot(name) }
    end

    # ignore: %w[ created_at updated_at id ]
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

      changed = added & removed
      [added - changed, removed - changed, changed]
    end
  end
end
