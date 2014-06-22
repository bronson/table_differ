describe TableDiff do
  it "takes a snapshot" do
    expect(model.snapshots.length).to eq 0
    model.create_snapshot
    expect(model.snapshots.length).to eq 1
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
