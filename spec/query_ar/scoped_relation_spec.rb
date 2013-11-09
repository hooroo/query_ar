require_relative '../support/fake_active_record_model'
require 'query_ar/scoped_relation'

describe ScopedRelation do

  describe "#scoped" do

    before do
      @scopes = { in_group: 'eat_drink', nearby_place_id: 'mamasita' }
      @model_class = FakeActiveRecordModel
      @model_class.applied_scopes = {}
    end

    it "applies the given scopes to the provided model class" do
      ScopedRelation.new(@model_class, @scopes).scoped
      expect(@model_class.applied_scopes).to eq @scopes
    end
  end

end