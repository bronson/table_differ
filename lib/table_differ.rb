require "active_support/concern"
require "active_record"


module TableDiffer
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
    # pass a date, receive a value worthy of being a table name
    def snapshot_name name
      if name.kind_of?(Date) || name.kind_of?(Time)
        name = name.strftime("%Y%m%d_%H%M%S")
      end

      unless name.index(table_name) == 0
        name = "#{table_name}_#{name}"
      end

      name
    end

    def snapshots
      connection.tables.grep(/^#{table_name}_/).sort
    end

    def create_snapshot name=Time.now
      connection.execute("CREATE TABLE #{snapshot_name(name)} AS SELECT * FROM #{table_name}")
    end

    def delete_snapshot name
      connection.execute("DROP TABLE #{snapshot_name(name)}")
    end

    def delete_snapshots &block
      # todo?
    end

    # ignore: %w[ created_at updated_at id ]
    def diff_snapshot oldtable=snapshots.last, newtable=table_name, options={}
      columns = column_names - (options[:ignore] || [])
      cols = columns.map { |c| "#{c} as #{c}" }.join(", ")

      added =   find_by_sql("SELECT #{cols} FROM #{newtable} EXCEPT SELECT #{cols} FROM #{oldtable}")
      removed = find_by_sql("SELECT #{cols} from #{oldtable} EXCEPT SELECT #{cols} FROM #{newtable}")
      changed = added & removed
      [added - changed, removed - changed, changed]
    end
  end
end
