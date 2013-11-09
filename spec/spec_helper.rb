# encoding: utf-8

require 'support/active_record/face'

# A class upon which we can base our query object.
# See ActiveRecord::Face for explanation on usage.
#
class User < ActiveRecord::Face
end

RSpec.configure do |config|
  config.before(:each) do |example|

    # Keep an eye on this. We want to make sure that our assertions about
    # messages receieved aren't skewed by a previous spec
    # User.messages_received = {}

    # Allow a class definition for the UserQuery to be passed into the
    # example group.
    if definition = example.class.metadata[:query_class_definition]
      create_query_class(definition)
    end
  end
end

# Enables us to create a different version of the UserQuery class
# depending on the requirements of the context / spec in question
#
def create_query_class(definition, class_name = 'UserQuery')
  Object.send(:remove_const, 'UserQuery') rescue NameError
  Object.class_eval definition
end