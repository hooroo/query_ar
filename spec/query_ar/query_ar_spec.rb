require 'spec_helper'
require 'query_ar'
require 'pry'

describe QueryAr do

  describe "Dsl" do

    describe ".defaults" do

      no_defaults = <<-RUBY
        class UserQuery
          include QueryAr
        end
      RUBY

      with_defaults = <<-RUBY
        class UserQuery
          include QueryAr

          defaults limit: 5, offset: 1, sort_by: 'name', sort_dir: 'DESC'
        end
      RUBY

      context "when no defaults are provided", query_class_definition: no_defaults do

        it "uses the global defaults" do
          UserQuery.new.all
          expect(User.messages_received).to include(limit:  [20])
          expect(User.messages_received).to include(offset: [0])
          expect(User.messages_received).to include(order:  ['id ASC'])
        end
      end

      context "when defaults are provided", query_class_definition: with_defaults do

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

      no_queryable_attrs = <<-RUBY
        class UserQuery
          include QueryAr
        end
      RUBY

      queryable_by_name = <<-RUBY
        class UserQuery
          include QueryAr

          queryable_by :name
        end
      RUBY

      let(:query_params) { {name: 'Stu'} }

      context "when no attributes have been declared", query_class_definition: no_queryable_attrs do

        it "does not query on anything" do
          UserQuery.new(query_params).all
          expect(User.messages_received).to include(where:  [{}])
        end
      end

      context "when attributes have been declared", query_class_definition: queryable_by_name do

        it "does not query on anything" do
          UserQuery.new(query_params).all
          expect(User.messages_received).to include(where:  [{name: 'Stu'}])
        end
      end
    end

    describe ".scopeable_by" do

    end

  end

end