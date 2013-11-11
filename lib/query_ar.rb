require "query_ar/version"
require 'query_ar/scoped_relation'
require 'query_ar/includes_parser'
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
    with_includes(scoped_relation)
      .where(query)
      .order(order)
      .limit(limit)
      .offset(offset)
  end

  def find(id_param = :id)
    with_includes(model_class).find(params[id_param])
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

  def includes
    @relations_to_include ||= IncludesParser.from_params(params)
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
  #     scopable_by  :in_group, :nearby_place_id
  #   end
  #
  module Dsl
    def defaults(options = {})
      self._defaults = options.symbolize_keys
    end

    def queryable_by(*keys)
      self._valid_query_keys = Set.new(keys.map(&:to_sym))
    end

    def scopable_by(*keys)
      self._valid_scope_keys = Set.new(keys.map(&:to_sym))
    end

    alias_method :scopeable_by, :scopable_by

  end

  private

  attr_reader :params

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
    [ sort_by, sort_dir].join(' ')
  end

  def sort_by
    params[:sort_by]
  end

  def sort_dir
    params[:sort_dir]
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

  def with_includes(relation)

    if includes.present?
      relation.includes(*includes)
    else
      relation
    end

  end

end
