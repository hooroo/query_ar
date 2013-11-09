require 'active_support/core_ext'

# For testing w/o ActiveRecord. This is a fake AR Model
# that will record all of the applied scopes.
#
class FakeActiveRecordModel

  class_attribute :applied_scopes

  def self.all
    self
  end

  # TODO: Make this syntax like AR scopes...
  #
  # scope :older_than, ->(years) { where("age > ?", years) }
  #
  def self.in_group(group)
    self.applied_scopes.merge!(in_group: group)
    self
  end

  def self.nearby_place_id(place_id)
    self.applied_scopes.merge!(nearby_place_id: place_id)
    self
  end

end