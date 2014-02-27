require "query_ar/version"
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
    @static_scopes = [ default_scope ]
  end

  def count
    all.count
  end

  def total
    scoped_relation.where(where_conditions).count
  end

  def all
     with_includes(scoped_relation)
      .where(where_conditions)
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
      sort_by: sort_by.gsub("#{base_table_name}.", ""),
      sort_dir: sort_dir,
      count: count,
      total: total
    }
  end

  def includes(*includes)
    @relation_includes = includes
    self
  end

  def with_scopes(*scopes)
    scopes.each do |scope|
      @static_scopes << scope
    end
    self
  end

  # Define and initialise the class-level _defaults Hash
  # and _valid_query_keys Set.
  #
  # Extend host class with macros when we're included.
  #
  def self.included(host_class)
    host_class.class_attribute :_defaults
    host_class._defaults = Hash.new

    host_class.class_attribute :_where_attribute_mappings
    host_class._where_attribute_mappings = {}

    host_class.class_attribute :_scope_attribute_mappings
    host_class._scope_attribute_mappings = {}

    host_class.extend(Dsl)
  end

  #  Module containing macros (class methods).
  #  Used to set defaults, which attributes can be
  #  queried and which scopes can be used.
  #  E.g.

  #   class PlaceQuery
  #     include ActiveRecordQuery

  #     defaults      sort_by: 'name', sort_dir: 'ASC'
  #     queryable_by  :name
  #     queryable_by  :group, as: :group_id
  #     queryable_by  :group, aliases_scope: :in_group
  #   end
  #
  module Dsl

    def defaults(options = {})
      self._defaults = options.symbolize_keys
    end

    def queryable_by(key, options = nil)

      if options
        if options[:aliases_scope]
          self._scope_attribute_mappings[key] = options[:aliases_scope]
        elsif options[:aliases_attribute]
          self._where_attribute_mappings[key.to_sym] = options[:aliases_attribute]
        end
      else
        self._where_attribute_mappings[key.to_sym] = key
      end

    end
  end

  private

  attr_reader :params, :relation_includes, :static_scopes

  def defaults
    GLOBAL_DEFAULTS.merge(self.class._defaults)
  end

  def where_conditions
    conditions = create_conditions_from_mappings(self.class._where_attribute_mappings)

    conditions.inject({}) do | disambiguated_conditions, (attr_name, value) |
      disambiguated_conditions["#{base_table_name}.#{attr_name}"] = value
      disambiguated_conditions
    end

  end

  def conditional_scopes
    create_conditions_from_mappings(self.class._scope_attribute_mappings)
  end

  def create_conditions_from_mappings(mappings)

    queryable_params = params.slice(*mappings.keys)

    queryable_params.inject({}) do | conditions, (attr_name, value) |
      mapped_attr_name = mappings[attr_name]
      conditions[mapped_attr_name] = value
      conditions
    end

  end

  def order
    [ sort_by, sort_dir ].join(' ')
  end

  def sort_by
    "#{base_table_name}.#{params[:sort_by]}"
  end

  def sort_dir
    params[:sort_dir]
  end

  def limit
    params[:limit].to_i
  end

  def offset
    params[:offset].to_i
  end

  def base_table_name
    model_class_name.underscore.pluralize
  end

  def model_class_name
    self.class.to_s.gsub('Query', '')
  end

  def model_class
    model_class_name.constantize
  end

  def scoped_relation

    statically_scoped = static_scopes.inject(model_class) do | scope_memo, (scope_name) |
      scope_memo.send(scope_name)
    end

    conditional_scopes.inject(statically_scoped) do | scope_memo, (scope_name, arg) |
      scope_memo.send(scope_name, arg)
    end

  end

  def with_includes(relation)
    return relation unless relation_includes.present?
    relation.includes(*relation_includes)
  end

  def default_scope
    ActiveRecord::VERSION::MAJOR < 4 ? :scoped : :all
  end

end
