describe TableDiffer do
  include_context "model"

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

  it "restores a snapshot" do
    # TODO: test that it doesn't delete any indices
    Model.create!(name: 'one')
    first_id = Model.first.id   # ensure the ID doesn't change
    snapshot = Model.create_snapshot('snapname')
    Model.create!(name: 'two')

    Model.restore_snapshot(snapshot)
    expect(Model.pluck(:id, :name).sort).to eq [[first_id, 'one']]

    Model.delete_snapshot(snapshot)
  end

  it "doesn't destroy the database if the snapshot can't be found" do
    snapshot = Model.create_snapshot('snapname')
    Model.create!(name: 'one')
    expect {
      Model.restore_snapshot(snapshot+' ')
    }.to raise_error(/doesn't exist/)
    expect(Model.count).to eq 1
    Model.delete_snapshot(snapshot)
  end

  it "deletes a named snapshot" do
    Model.create_snapshot('snapname')
    expect(Model.snapshots.size).to eq 1
    Model.delete_snapshot('snapname')
    expect(Model.snapshots.size).to eq 0
  end

  it "deletes all snapshots" do
    Model.create_snapshot('snapname')
    expect(Model.snapshots.size).to eq 1
    Model.delete_snapshots
    expect(Model.snapshots.size).to eq 0
  end

  it "doesn't delete snapshots if none specified" do
    Model.create_snapshot('snapname')
    expect(Model.snapshots.size).to eq 1
    Model.delete_snapshots []
    expect(Model.snapshots.size).to eq 1
    Model.delete_snapshots(Model.snapshots)
    expect(Model.snapshots.size).to eq 0
  end

  it "deletes a block of snapshots" do
    Model.create_snapshot('21')
    Model.create_snapshot('22')
    Model.create_snapshot('33')

    Model.delete_snapshots { |name| name == 'models_22' || name == 'models_33' }
    expect(Model.snapshots.sort).to eq ['models_21']
  end
end
