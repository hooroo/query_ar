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
          let(:params) { {limit: 10, offset: 20} }

          it "uses those ones where available" do
            UserQuery.new(params).all
            expect(User.messages_received).to include(limit:  [10])
            expect(User.messages_received).to include(offset: [20])
            expect(User.messages_received).to include(order:  ['name DESC'])
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
    end

    describe ".scopable_by" do

      let(:params) { {older_than: 30, younger_than: 50} }

      no_scopes = <<-RUBY
        class UserQuery
          include QueryAr
        end
      RUBY

      context "when NO scopes have been declared", query_class: no_scopes do

        it "will not query on any scopes" do
          UserQuery.new(params).all
          expect(User.messages_received.keys).to_not include(:older_than)
          expect(User.messages_received.keys).to_not include(:younger_than)
        end
      end

      with_scopes = <<-RUBY
        class UserQuery
          include QueryAr

          scopable_by :older_than
        end
      RUBY

      context "when scopes have been declared", query_class: with_scopes do
        it "will query on matching scopes" do
          UserQuery.new(params).all
          expect(User.messages_received).to include(older_than: [30])
          expect(User.messages_received.keys).to_not include(:younger_than)
        end
      end
    end

    describe ".includable" do

      let(:params) { {include: 'images'} }

      no_includes = <<-RUBY
        class UserQuery
          include QueryAr
        end
      RUBY

      context "when NO includables have been declared", query_class: no_includes do

        it "does not include any relations" do
          UserQuery.new(params).all
          expect(User.messages_received.keys).to_not include(:includes)
        end
      end

      with_includes = <<-RUBY
        class UserQuery
          include QueryAr

          includable :images, { :reviews => [ :author ]}
        end
      RUBY

      context "when includables have been declared", query_class: with_includes do

        it "includes only the includable relations" do
          UserQuery.new(params).all
          expect(User.messages_received).to include(includes: [:images])
        end
      end
    end

  end

  describe "find" do

    no_includes = <<-RUBY
      class UserQuery
        include QueryAr
      end
    RUBY

    context "when NO includes have been provided", query_class: no_includes do

      let(:params) { {id: 1} }

      it "finds by id from params" do
        UserQuery.new(params).find
        expect(User.messages_received).to include(find: [1])
      end

    end

    with_includes = <<-RUBY
      class UserQuery
        include QueryAr

        includable :images, { :reviews => [ :author ]}, :comments
      end
    RUBY

    context "when includes have been provided", query_class: with_includes do

      let(:params) { {id: 1, include: 'images,reviews.author'} }

      it "finds by id from params, including the specified graph" do
        UserQuery.new(params).find
        expect(User.messages_received).to include(find: [1])
        expect(User.messages_received).to include(includes: [:images, {reviews: [:author]}])
      end

    end

  end

end
