require "active_support/concern"
require "active_record"


module TableDiffer
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
    def snapshots
    end

    def snapshot_name date
    end

    def create_snapshot name=snapshot_name(Time.now)
    end

    def delete_snapshot name
    end

    def delete_snapshots &block
    end

    def diff
    end
  end
end
