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
          expect(User.messages_received).to include(order:  ['users.id ASC'])
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
          expect(User.messages_received).to include(order:  ['users.name DESC'])
        end

        context "when the query params specify values" do
          let(:params) { {limit: 10, offset: 20} }

          it "uses those ones where available" do
            UserQuery.new(params).all
            expect(User.messages_received).to include(limit:  [10])
            expect(User.messages_received).to include(offset: [20])
            expect(User.messages_received).to include(order:  ['users.name DESC'])
          end
        end
      end
    end

    describe ".queryable_by" do

      let(:params) { {name: 'Stu', role: 'admin'} }

      no_queryable_attrs = <<-RUBY
        class UserQuery
          include QueryAr
        end
      RUBY

      context "when NO queryable attributes have been declared", query_class: no_queryable_attrs do

        it "does not query on anything" do
          UserQuery.new(params).all
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
          UserQuery.new(params).all
          expect(User.messages_received).to include(where: [{name: 'Stu'}])
          expect(User.messages_received).to_not include(where: [{role: 'admin'}])
        end
      end

      queryable_by_alias = <<-RUBY
        class UserQuery
          include QueryAr

          queryable_by :name, aliases_attribute: :other_name
        end
      RUBY

      context "when queryable attributes have been aliased", query_class: queryable_by_alias do

        it "queries using the aliased attribute" do
          UserQuery.new(params).all
          expect(User.messages_received).to include(where: [{other_name: 'Stu'}])
        end
      end


      queryable_by_aliased_scope = <<-RUBY
        class UserQuery
          include QueryAr

          queryable_by :age_greater_than, aliases_scope: :older_than
        end
      RUBY

      context "when queryable attributes have been aliased to a scope", query_class: queryable_by_aliased_scope do

        let(:params) { {age_greater_than: 21} }

        it "queries on the aliased scope" do
          UserQuery.new(params).all
          expect(User.messages_received).to include(older_than: [21])
        end
      end

    end

  end

  describe "find" do

    user_query = <<-RUBY
      class UserQuery
        include QueryAr
      end
    RUBY

    let(:params) { {id: 1} }

    describe "finding by id", query_class: user_query do

      it "finds by id from params" do
        UserQuery.new(params).find
        expect(User.messages_received).to include(find: [1])
      end
    end

  end

  describe "includes" do

    user_query = <<-RUBY
      class UserQuery
        include QueryAr
      end
    RUBY

    describe "including relations in the query", query_class: user_query do

      it "adds includes to the relation" do
        UserQuery.new.includes(:a, :b).all
        expect(User.messages_received).to include(includes: [:a, :b])
      end

      it "doesn't add includes to the relation if none provided" do
        UserQuery.new.all
        expect(User.messages_received).to_not include(includes: [])
        expect(User.messages_received).to_not include(includes: nil)
      end

    end

  end

end
