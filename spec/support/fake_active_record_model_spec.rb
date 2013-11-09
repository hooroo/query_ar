require_relative 'fake_active_record_model'

# Make sure the fake model works before testing
# implementation code with it.
#
describe FakeActiveRecordModel do

  before do
    @model_class = FakeActiveRecordModel
    @model_class.applied_scopes = {}
  end

  it "takes record of applied scopes" do
    @model_class.in_group('eat_drink')
    expect(@model_class.applied_scopes).to eq({in_group: 'eat_drink'})

    @model_class.nearby_place_id('mamasita')
    expect(@model_class.applied_scopes).to eq({in_group: 'eat_drink', nearby_place_id: 'mamasita'})
  end

  it "allows chaining" do
    @model_class.all.in_group('eat_drink').nearby_place_id('mamasita')
    expect(@model_class.applied_scopes).to eq({in_group: 'eat_drink', nearby_place_id: 'mamasita'})
  end

end