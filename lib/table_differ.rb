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

    def diff
    end
  end
end
