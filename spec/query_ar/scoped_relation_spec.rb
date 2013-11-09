require 'active_support/core_ext'
require 'query_ar/scoped_relation'

# For testing w/o ActiveRecord. This is a fake AR Model
# that will record all of the applied scopes.
#
class FakeActiveRecordModel

  class_attribute :applied_scopes

  def self.all
    self
  end

  def self.in_group(group)
    self.applied_scopes.merge!(in_group: group)
    self
  end

  def self.nearby_place_id(place_id)
    self.applied_scopes.merge!(nearby_place_id: place_id)
    self
  end

end

# Make sure the fake model works before testing
# implementation code with it.
#
describe FakeActiveRecordModel do

  it "takes record of applied scopes" do

    fake = FakeActiveRecordModel
    fake.applied_scopes = {}
    expect(fake.applied_scopes).to eq({})

    fake.in_group('eat_drink')
    expect(fake.applied_scopes).to eq({in_group: 'eat_drink'})

    fake.nearby_place_id('mamasita')
    expect(fake.applied_scopes).to eq({in_group: 'eat_drink', nearby_place_id: 'mamasita'})
  end

  it "allows chaining" do

    fake = FakeActiveRecordModel
    fake.applied_scopes = {}
    expect(fake.applied_scopes).to eq({})

    fake.all.in_group('eat_drink').nearby_place_id('mamasita')
    expect(fake.applied_scopes).to eq({in_group: 'eat_drink', nearby_place_id: 'mamasita'})
  end

end

# Down to business...
#
describe ScopedRelation do

  describe "#scoped" do

    let(:scopes)      { {in_group: 'eat_drink', nearby_place_id: 'mamasita'} }
    let(:model_class) { FakeActiveRecordModel }

    it "applies the given scopes to the provided model class" do
      ScopedRelation.new(model_class, scopes).scoped
      expect(model_class.applied_scopes).to eq scopes
    end
  end

end