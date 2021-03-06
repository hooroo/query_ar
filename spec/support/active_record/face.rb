# To avoid having ActiveRecord as a development dependency of
# this gem (whose sole purpose is to chain AR queries - YOLO),
# we use this class in tests. Usage is as follows.

# Declare a class that inherits us instead of AR::Base
#
#   class User < ActiveRecord::Face
#     scope :active
#   end

# Chain a bunch of query methods together
#
#   > User.active.where(name: 'stu').order('name').limit(10).offset(0)

# Find out what messages where received and with what args, useful for assertions
#
#   > User.messages_received
#   => {:active=>[], :where=>[{:name=>"stu"}], :order=>["name"], :limit=>[10], :offset=>[0]}

require 'active_support/core_ext'

module ActiveRecord
  module VERSION
    MAJOR = 4
    STRING = '4'
  end
end

module ActiveRecord
  class Face

    class_attribute :messages_received, :expected_messages

    self.expected_messages = Set.new([
      :all,
      :where,
      :distinct,
      :order,
      :limit,
      :offset,
      :includes,
      :references,
      :find,
      :find_by,
      :group
    ])

    def self.pluck(attr)
      []
    end

    def self.scope(name)
      self.expected_messages << name.to_sym
    end

    def self.method_missing(method, *args, &block)
      super unless self.expected_messages.include?(method)

      self.messages_received ||= {}
      calls = self.messages_received[method] ||= []
      calls << args
      self
    end

  end
end
