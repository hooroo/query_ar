require 'spec_helper'
require 'query_ar/scoped_relation'

# A class upon which we can base our query object.
# See ActiveRecord::Face for explanation on usage.
#
class User < ActiveRecord::Face
end

describe ScopedRelation do

  describe "#scoped" do

    it "returns the relation with all scopes applied" do
      scopes = {older_than: 30, younger_than: 50}
      ScopedRelation.new(User, scopes).scoped
      expect(User.messages_received).to include(older_than: [30])
      expect(User.messages_received).to include(younger_than: [50])
    end
  end

end