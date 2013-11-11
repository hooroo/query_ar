require 'spec_helper'
require 'query_ar'

# A class upon which we can base our query object.
# See ActiveRecord::Face for explanation on usage.
#
class User < ActiveRecord::Face
  scope :younger_than
  scope :older_than
end

describe QueryAr do

  describe "Dsl" do

    describe ".defaults" do

      no_defaults = <<-RUBY
        class UserQuery
          include QueryAr
        end
      RUBY

      context "when NO defaults are provided", query_class: no_defaults do

        it "uses the global defaults" do
          UserQuery.new.all
          expect(User.messages_received).to include(limit:  [20])
          expect(User.messages_received).to include(offset: [0])
          expect(User.messages_received).to include(order:  ['id ASC'])
        end
      end

      with_defaults = <<-RUBY
        class UserQuery
          include QueryAr

          defaults limit: 5, offset: 1, sort_by: 'name', sort_dir: 'DESC'
        end
      RUBY

      context "when defaults are provided", query_class: with_defaults do

        it "uses the provided defaults" do
          UserQuery.new.all
          expect(User.messages_received).to include(limit:  [5])
          expect(User.messages_received).to include(offset: [1])
          expect(User.messages_received).to include(order:  ['name DESC'])
        end

        context "when the query params specify values" do
          let(:query_params) { {limit: 10, offset: 20} }

          it "uses those ones where available" do
            UserQuery.new(query_params).all
            expect(User.messages_received).to include(limit:  [10])
            expect(User.messages_received).to include(offset: [20])
            expect(User.messages_received).to include(order:  ['name DESC'])
          end
        end
      end
    end

    describe ".queryable_by" do

      let(:query_params) { {name: 'Stu', role: 'admin'} }

      no_queryable_attrs = <<-RUBY
        class UserQuery
          include QueryAr
        end
      RUBY

      context "when NO queryable attributes have been declared", query_class: no_queryable_attrs do

        it "does not query on anything" do
          UserQuery.new(query_params).all
          expect(User.messages_received).to include(where: [{}])
        end
      end

      queryable_by_name = <<-RUBY
        class UserQuery
          include QueryAr

          queryable_by :name
        end
      RUBY

      context "when queryable attributes have been declared", query_class: queryable_by_name do

        it "queries on the allowed attribute only" do
          UserQuery.new(query_params).all
          expect(User.messages_received).to include(where: [{name: 'Stu'}])
          expect(User.messages_received).to_not include(where: [{role: 'admin'}])
        end
      end
    end

    describe ".scopeable_by" do

      let(:query_params) { {older_than: 30, younger_than: 50} }

      no_scopes = <<-RUBY
        class UserQuery
          include QueryAr
        end
      RUBY

      context "when NO scopes have been declared", query_class: no_scopes do

        it "will not query on any scopes" do
          UserQuery.new(query_params).all
          expect(User.messages_received.keys).to_not include(:older_than)
          expect(User.messages_received.keys).to_not include(:younger_than)
        end
      end

      with_scopes = <<-RUBY
        class UserQuery
          include QueryAr

          scopeable_by :older_than
        end
      RUBY

      context "when scopes have been declared", query_class: with_scopes do
        it "will query on matching scopes" do
          UserQuery.new(query_params).all
          expect(User.messages_received).to include(older_than: [30])
          expect(User.messages_received.keys).to_not include(:younger_than)
        end
      end
    end

    describe ".include" do

      user_query = <<-RUBY
        class UserQuery
          include QueryAr
        end
      RUBY

      context "with includes passed", query_class: user_query do
        it "adds the includes to the relation" do
          UserQuery.new({}).includes(:a).all
          expect(User.messages_received).to include(includes: [:a])
        end
      end

      context "with empty includes", query_class: user_query do
        it "does not pass includes to the relation" do
          UserQuery.new({}).includes().all
          expect(User.messages_received.keys).to_not include(:includes)
        end
      end

    end

  end

end