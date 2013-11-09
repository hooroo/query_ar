require 'active_support/core_ext'

# To avoind having ActiveRecord as a development dependency of
# this gem (whose sole purpose is to chain AR queries), we use
# this class in tests. Usage is as follows.

# Declare a class that inherits us instead of AR::Base
#
#   class User < ActiveRecord::Face
#   end

# Chain a bunch of query methods together
#
#   > User.active.where(name: 'stu').order('name').limit(10).offset(0)

# Find out what messages where received and with what args, useful for assertions
#
#   > User.messages_received
#   => {:active=>[], :where=>[{:name=>"stu"}], :order=>["name"], :limit=>[10], :offset=>[0]}

module ActiveRecord
  class Face

    class_attribute :messages_received

    def self.method_missing(method, *args, &block)
      self.messages_received ||= {}
      self.messages_received.merge!(method => args)
      self
    end

  end
end