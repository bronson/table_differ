describe TableDiffer do
  # around(:all) do |group|
  #   # puts 'before'
  #   # group.run_examples
  #   # puts 'after'
  # end

  class Model < ActiveRecord::Base
    include TableDiffer
  end

  before(:each) do
    Model.create!(name: 'one')
    Model.create!(name: 'two')
    Model.create_snapshot('original')
  end

  it "detects no changes" do
    added,removed = Model.diff_snapshot
    expect(added).to eq []
    expect(removed).to eq []
  end

  it "detects an added record" do
    three = Model.create!(name: 'three')
    added,removed = Model.diff_snapshot
    expect(added).to eq [three]
    expect(removed).to eq []
  end

  it "detects a removed record" do
    two = Model.where(name: 'two').first.destroy
    added,removed = Model.diff_snapshot
    expect(added).to eq []
    expect(removed).to eq [two]
  end

  it "detects a changed field" do
    one = Model.where(name: 'one').first
    one.update_attributes!(name: 'uno')
    added,removed = Model.diff_snapshot
    expect(added).to eq [one]
    expect(removed).to eq [one]
  end
end
