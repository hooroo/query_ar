# encoding: utf-8

require 'support/active_record/face'

RSpec.configure do |config|

  config.before(:each) do |example|
    # Allow a class definition for the UserQuery
    # to be passed into the example group.
    if definition = example.class.metadata[:query_class]
      create_query_class(definition)
    end
    #TODO - Remove hardcoding of User related stuff.
    User.messages_received = nil
  end

  config.after(:each) do |example|
    remove_query_class if example.class.metadata[:query_class]
  end
end

# Enables us to create a different version of the UserQuery class
# depending on the requirements of the context / spec in question
#
def create_query_class(definition, class_name = 'UserQuery')
  Object.class_eval definition
end

def remove_query_class
  Object.send(:remove_const, 'UserQuery') rescue NameError
end