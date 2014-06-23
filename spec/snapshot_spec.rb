describe TableDiffer do
  class Model < ActiveRecord::Base
    include TableDiffer
  end

  it "takes a snapshot" do
    expect(Model.snapshots.size).to eq 0
    Model.create_snapshot
    expect(Model.snapshots.size).to eq 1
  end

  it "takes a name for a snapshot" do
    expect(Model.snapshots.size).to eq 0
    Model.create_snapshot('snapname')
    expect(Model.snapshots).to eq ['models_snapname']
  end

  it "errors out if asked to create a duplicate snapshot" do
    Model.create_snapshot('snapname')
    expect {
      Model.create_snapshot('snapname')
    }.to raise_error(ActiveRecord::StatementInvalid, /already exists/)
  end

  it "returns a list of snapshots" do
    Model.create_snapshot('aiee')
    Model.create_snapshot('bee')
    Model.create_snapshot('cee')
    expect(Model.snapshots.sort).to eq ['models_aiee', 'models_bee', 'models_cee']
  end

  it "deletes a named snapshot" do
    Model.create_snapshot('snapname')
    expect(Model.snapshots.size).to eq 1
    Model.delete_snapshot('snapname')
    expect(Model.snapshots.size).to eq 0
  end

  it "deletes a bunch of snapshots" do
  end
end
