describe "diffing a model" do
  include_context "surrogate_model"

  it "detects a changed field using a single surrogate" do
    first = SurrogateModel.create!(name: 'one', original_name: 'one')
    second = SurrogateModel.create!(name: 'two', original_name: 'two')

    SurrogateModel.create_snapshot('original')

    first.update_attributes!(name: 'uno')
    third = SurrogateModel.create!(name: 'three', original_name: 'three')
    second.destroy!

    added,removed,changed = SurrogateModel.diff_snapshot(ignore: :id, unique_by: :original_name)

    # we can find added and changed records by surrogate IDs but, of course, can't find removed ones
    expect(added).to eq [third]
    expect(added.first.original_attributes).to eq nil
    expect(removed.map(&:attributes)).to eq [{"id" => nil, "name" => "two", "original_name" => "two", "alternate_value" => nil}]
    expect(removed.first.original_attributes).to eq nil
    expect(changed).to eq [first]
    expect(changed.first.name).to eq 'uno'
    expect(changed.first.original_attributes).to eq({"id" => nil, "name" => 'one', "original_name" => 'one', "alternate_value" => nil})
  end

  it "detects a changed field using a composite surrogate" do
    first = SurrogateModel.create!(name: 'one', original_name: 'one', alternate_value: 1)
    second = SurrogateModel.create!(name: 'one', original_name: 'one', alternate_value: 2)
    third = SurrogateModel.create!(name: 'one', original_name: 'one', alternate_value: 3)

    SurrogateModel.create_snapshot('original')

    second.update_attributes!(name: 'uno')

    added,removed,changed = SurrogateModel.diff_snapshot(ignore: :id, unique_by: [:original_name, 'alternate_value'])

    expect(added).to eq []
    expect(removed).to eq []
    expect(changed).to eq [second]   # the alternate value should ensure we pick up the correct record
  end
end
