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

  # ids make it soooo much easier to dedup and check equality
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
      expect(removed).to eq []
      expect(changed).to eq []
    end

    it "detects a removed record" do
      two = Model.where(name: 'two').first.destroy
      added,removed,changed = Model.diff_snapshot

      expect(added).to eq []
      expect(removed).to eq [two]
      expect(changed).to eq []
    end

    it "detects a changed field" do
      one = Model.where(name: 'one').first
      one.update_attributes!(name: 'uno')
      added,removed,changed = Model.diff_snapshot

      expect(added).to eq []
      expect(removed).to eq []
      expect(changed).to eq [one]
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
      expect(removed).to eq []
    end

    it "detects a removed record" do
      Model.where(name: 'two').first.destroy
      added,removed,changed = Model.diff_snapshot(ignore: :id)

      expect(added).to eq []
      expect(removed.map(&:attributes)).to eq [{"id" => nil, "name" => "two"}]
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
  end
end
