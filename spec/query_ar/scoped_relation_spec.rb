require 'spec_helper'
require 'query_ar/scoped_relation'

# A class upon which we can base our query object.
# See ActiveRecord::Face for explanation on usage.
#
class Property < ActiveRecord::Face
  scope :max_price
  scope :min_price
end

describe ScopedRelation do

  describe "#scoped" do

    it "returns the relation with all scopes applied" do
      scopes = {min_price: 0, max_price: 1_000_000}
      ScopedRelation.new(Property, scopes).scoped
      expect(Property.messages_received).to include(min_price: [0])
      expect(Property.messages_received).to include(max_price: [1_000_000])
    end
  end

end