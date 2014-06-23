require "active_support/concern"
require "active_record"


module TableDiffer
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
    # pass a date, receive a value worthy of being a table name
    def snapshot_name date
      date.strftime("%Y%m%d_%H%M%S")
    end

    def snapshots
      connection.tables.grep(/^#{table_name}_/).sort
    end

    def create_snapshot name=snapshot_name(Time.now)
      connection.execute("CREATE TABLE #{table_name + '_' + name} AS SELECT * FROM #{table_name}")
    end

    def delete_snapshot name
      connection.execute("DROP TABLE #{table_name + '_' + name}")
    end

    def delete_snapshots &block
      # todo?
    end

    def diff
    end
  end
end
