require "query_ar/version"
require 'query_ar/scoped_relation'
require 'active_support/core_ext'

module QueryAr

  # Hmmmm - probably too presumptuous.
  # Make this confugurable at the app-level?
  GLOBAL_DEFAULTS = {
    limit:    20,
    offset:   0,
    sort_by:  'id',
    sort_dir: 'ASC'
  }

  def initialize(params = {})
    params = params.symbolize_keys
    params.keep_if { |k,v| v.present? }
    @params = defaults.merge(params)
  end

  def count
    all.count
  end

  def total
    scoped_relation.where(query).count
  end

  def all
    scoped_relation_with_includes
      .where(query)
      .order(order)
      .limit(limit)
      .offset(offset)
  end

  def includes(*relation_names)
    @relations_to_include = relation_names
    self
  end

  def summary
    {
      offset: offset,
      limit: limit,
      sort_by: sort_by,
      sort_dir: sort_dir,
      count: count,
      total: total
    }
  end

  # Define and initialise the class-level _defaults Hash
  # and _valid_query_keys Set.
  #
  # Extend host class with macros when we're included.
  #
  def self.included(host_class)
    host_class.class_attribute :_defaults
    host_class._defaults = Hash.new

    host_class.class_attribute :_valid_query_keys
    host_class._valid_query_keys = Set.new

    host_class.class_attribute :_valid_scope_keys
    host_class._valid_scope_keys = Set.new

    host_class.extend(Dsl)
  end

  #  Module containing macros (class methods).
  #  Used to set defaults, which attributes can be
  #  queried and which scopes can be used.
  #  E.g.

  #   class PlaceQuery
  #     include ActiveRecordQuery

  #     defaults      sort_by: 'name', sort_dir: 'ASC'
  #     queryable_by  :name, :street_address
  #     scopeable_by  :in_group, :nearby_place_id
  #   end
  #
  module Dsl
    def defaults(options = {})
      self._defaults = options.symbolize_keys
    end

    def queryable_by(*keys)
      self._valid_query_keys = Set.new(keys.map(&:to_sym))
    end

    def scopeable_by(*keys)
      self._valid_scope_keys = Set.new(keys.map(&:to_sym))
    end
  end

  private

  attr_reader :params, :relations_to_include

  def defaults
    GLOBAL_DEFAULTS.merge(self.class._defaults)
  end

  def query
    params.slice(*self.class._valid_query_keys)
  end

  def scopes
    params.slice(*self.class._valid_scope_keys)
  end

  def order
    [ params[:sort_by], params[:sort_dir] ].join(' ')
  end

  def limit
    params[:limit]
  end

  def offset
    params[:offset]
  end

  def model_class
    self.class.to_s.gsub('Query', '').constantize
  end

  def scoped_relation
    ScopedRelation.new(model_class, scopes).scoped
  end

  def scoped_relation_with_includes

    if relations_to_include == nil || relations_to_include.empty?
      scoped_relation
    else
      scoped_relation.includes(*relations_to_include)
    end

  end

end
