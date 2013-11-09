require 'active_support/core_ext'

module ActiveRecord
  class Bass

    class_attribute :messages_received

    def self.method_missing(method, *args, &block)
      self.messages_received ||= {}
      self.messages_received.merge!(method => args)
      self
    end

  end
end