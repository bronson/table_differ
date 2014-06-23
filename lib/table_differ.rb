require "active_support/concern"
require "active_record"


module TableDiffer
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
    # pass a date, receive a value worthy of being a table name
    def snapshot_name date
      table_name + '_' + date.strftime("%Y%m%d_%H%M%S")
    end

    def snapshots
      connection.tables.grep(/^#{table_name}_/).sort
    end

    def create_snapshot name=snapshot_name(Time.now)
      connection.execute("CREATE TABLE #{name} AS SELECT * FROM #{table_name}")
    end

    def delete_snapshot name
    end

    def delete_snapshots &block
    end

    def diff
    end
  end
end
