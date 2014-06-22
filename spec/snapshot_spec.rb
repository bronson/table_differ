describe TableDiffer do
  class Model < ActiveRecord::Base
    include TableDiffer
  end

  # let model { Model.new }

  it "takes a snapshot" do
  end

  it "takes a name for a snapshot" do
    model.create_snapshot 'mysnapshot'
  end

  it "errors out if asked to create a duplicate snapshot" do
  end

  it "returns a list of snapshots" do
  end

  it "deletes a named snapshot" do
  end

  it "deletes a bunch of snapshots" do
  end
end
