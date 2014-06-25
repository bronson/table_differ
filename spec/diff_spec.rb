describe "diffing a model" do
  include_context "model"

  before(:each) do
    Model.create!(name: 'one')
    Model.create!(name: 'two')
    Model.create_snapshot('original')
  end

  # around(:all) do |group|
  #   # puts 'before'
  #   # group.run_examples
  #   # puts 'after'
  # end


  describe "with IDs" do
    it "detects no changes" do
      added,removed,changed = Model.diff_snapshot

      expect(added).to eq []
      expect(removed).to eq []
      expect(changed).to eq []
    end

    it "detects an added record" do
      three = Model.create!(name: 'three')
      added,removed,changed = Model.diff_snapshot

      expect(added).to eq [three]
      expect(added.first.new_record?).to eq false
      expect(removed).to eq []
      expect(changed).to eq []

      # added records are normal AR objects, try using it
      added.first.update_attributes!(name: 'trois')
      expect(Model.find(added.first.id).name).to eq 'trois'
    end

    it "detects a removed record" do
      two = Model.where(name: 'two').first.destroy
      added,removed,changed = Model.diff_snapshot

      expect(added).to eq []
      expect(removed).to eq [two]
      expect(removed.first.new_record?).to eq false
      expect(changed).to eq []

      # calling save on the returned record should do nothing
      expect(Model.count).to eq 1
      removed.first.save!
      expect(Model.count).to eq 1
    end

    it "detects a changed field" do
      one = Model.where(name: 'one').first
      one.update_attributes!(name: 'uno')
      added,removed,changed = Model.diff_snapshot

      expect(added).to eq []
      expect(removed).to eq []
      expect(changed).to eq [one]
      expect(changed.first.name).to eq 'uno'

      # changed records are normal AR objects, try using it
      changed.first.update_attributes!(name: 'nuevo')
      expect(Model.find(changed.first.id).name).to eq 'nuevo'
    end

    it "resurrects a removed record" do
      Model.where(name: 'two').first.destroy
      _,removed,_ = Model.diff_snapshot

      expect(Model.count).to eq 1
      # we're expicitly setting the ID to the previous ID, that might not be ok?
      Model.create!(removed.first.attributes)
      expect(Model.count).to eq 2

      # and now there are no differences
      differences = Model.diff_snapshot
      expect(differences).to eq [[], [], []]
    end
  end


  # if we can't trust the model's primary key, we can't tell if anything
  # changed.  we can only see what's new and what's been deleted.
  describe "ignoring IDs" do
    it "detects no changes" do
      added,removed,changed = Model.diff_snapshot(ignore: :id)

      expect(added).to eq []
      expect(removed).to eq []
      expect(changed).to eq []
    end

    it "detects an added record" do
      Model.create!(name: 'three')
      added,removed = Model.diff_snapshot(ignore: :id)

      expect(added.map(&:attributes)).to eq [{"id" => nil, "name" => "three"}]
      expect(added.first.new_record?).to eq false  # oh well
      expect(removed).to eq []

      # wthout an ID, updating attributes should do nothing
      added.first.update_attributes!(name: 'trois')
      expect(Model.count).to eq 3
      expect(Model.pluck(:name).sort).to eq ['one', 'three', 'two']  # no trois
    end

    it "detects a removed record" do
      Model.where(name: 'two').first.destroy
      added,removed,changed = Model.diff_snapshot(ignore: :id)

      expect(added).to eq []
      expect(removed.map(&:attributes)).to eq [{"id" => nil, "name" => "two"}]
      expect(removed.first.new_record?).to eq false  # oh well
      expect(changed).to eq []
    end

    # without an ID, we can't tell if anything changed
    it "detects a changed field" do
      one = Model.where(name: 'one').first
      one.update_attributes!(name: 'uno')
      added,removed,changed = Model.diff_snapshot(ignore: :id)

      expect(added.map(&:attributes)).to eq [{"id" => nil, "name" => "uno"}]
      expect(removed.map(&:attributes)).to eq [{"id" => nil, "name" => "one"}]
      expect(changed).to eq []
    end

    it "resurrects a removed record" do
      Model.where(name: 'two').first.destroy
      _,removed,_ = Model.diff_snapshot(ignore: :id)

      expect(Model.count).to eq 1
      Model.create!(removed.first.attributes)
      expect(Model.count).to eq 2

      differences = Model.diff_snapshot(ignore: :id)
      expect(differences).to eq [[], [], []]
    end
  end

  # ensure we select the correct snapshots to diff between
  describe "with a bunch of snapshots" do
    it "uses the most recent snapshot" do
      insecond = Model.create!(name: 'only in second')
      Model.create_snapshot('second')
      main = Model.create!(name: 'only in main table')


      # each of the following is an individual test.
      # not sure how I can make them all use the same db setup though.
      # rspec really really needs a before(:all) { }.

      # first make sure default diffs newer table
      differences = Model.diff_snapshot
      expect(differences).to eq [[main], [], []]

      # now diff against older snapshot, ensure more changes
      differences = Model.diff_snapshot old: 'original'
      expect(differences).to eq [[insecond, main], [], []]

      # specifying an older snapshot produces a reverse diff against the most recent snapshot
      differences = Model.diff_snapshot new: 'models_original'
      expect(differences).to eq [[], [insecond], []]

      # finally, specify two named snapshots
      differences = Model.diff_snapshot old: 'original', new: 'models_second'
      expect(differences).to eq [[insecond], [], []]
    end
  end
end
