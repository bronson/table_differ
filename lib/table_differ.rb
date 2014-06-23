require "active_support/concern"
require "active_record"


module TableDiffer
  extend ActiveSupport::Concern

  module ClassMethods
    # pass a date or name fragment, receive the full snapshot name.
    # it's ok to pass a snapshot name; it will be returned unchaged.
    def snapshot_name name
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

    def delete_snapshots
      snapshots.each do |name|
        if yield(name)
          delete_snapshot(name)
        end
      end
    end

    # ignore: %w[ created_at updated_at id ]
    def diff_snapshot options={}
      oldtable = options[:old] || snapshots.last
      newtable = options[:new] || table_name

      ignore = []
      if options[:ignore]
        ignore = Array(options[:ignore]).map(&:to_s)
      end

      columns = column_names - ignore
      cols = columns.map { |c| "#{c} as #{c}" }.join(", ")

      added =   find_by_sql("SELECT #{cols} FROM #{newtable} EXCEPT SELECT #{cols} FROM #{oldtable}")
      removed = find_by_sql("SELECT #{cols} from #{oldtable} EXCEPT SELECT #{cols} FROM #{newtable}")

      changed = added & removed
      [added - changed, removed - changed, changed]
    end
  end
end
