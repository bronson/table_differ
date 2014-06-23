describe TableDiffer do
  class Model < ActiveRecord::Base
    include TableDiffer
  end

  # let model { Model.new }

  it "takes a snapshot" do
    expect(Model.snapshots.size).to eq 0
    Model.create_snapshot
    expect(Model.snapshots.size).to eq 1
  end

  it "takes a name for a snapshot" do
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
