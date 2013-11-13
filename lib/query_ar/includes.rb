require 'active_support/core_ext'

# Hopefully the spec is robust enough that we can
# break this down and refactor as we go. I'm not
# happy with the complexity of it, but it's a
# reasonably complex problem
# ~ Stu

module QueryAr
  class Includes
    include Comparable
    include Enumerable

    def initialize(*includes)
      @includes = includes.compact
    end

    def self.from_params(params)
      from_string(params[:include])
    end

    def self.from_string(string)
      return new if string.blank?

      includes_hash = build_hash_from_string(string)
      new(*flatten(includes_hash))
    end

    def to_s
      @to_s ||= begin
        paths = []
        includes.each do |item|
          if item.is_a? Hash
            stringify_keys(paths, item)
          else
            paths << [item]
          end
        end
        paths = paths.map { |p| p.join('.') }
        paths.sort.join(',')
      end
    end

    def include?(key)
      includes.include? key
    end

    def present?
      includes.present?
    end

    def each(&block)
      includes.each do |include|
        if block_given?
          block.call include
        else
          yield include
        end
      end
    end

    def &(other_includes)
      hash = self.class.build_hash_from_string(to_s)
      other_hash = self.class.build_hash_from_string(other_includes.to_s)

      intersected_paths = (to_s.split(',') & other_includes.to_s.split(','))
      self.class.from_string(intersected_paths.join(','))
    end

    def <=>(other_includes)
      to_s <=> other_includes.to_s
    end

    def inspect
      includes.inspect
    end

    private

    attr_accessor :includes

    def self.build_hash_from_string(string)
      includes_hash = {}
      include_paths = string.split(',').map { |path| path.split('.') }

      include_paths.each do |path|
        current_hash = includes_hash
        path.each do |token|
          current_hash[token] ||= {}
          current_hash = current_hash[token]
        end
      end
      includes_hash
    end

    def stringify_keys(top_level_paths, hash, path_attrs = [])
      current_key = hash.keys.first
      path_attrs << current_key
      top_level_paths << path_attrs.dup

      hash[current_key].each do |path_value|
        if path_value.is_a? Hash
          path_attrs << stringify_keys(top_level_paths, path_value, path_attrs)
        else
          top_level_paths << (path_attrs.dup << path_value)
        end
      end
    end

    # Turns this:
    #
    # [ :tags, {images: [:comments]}, {reviews: [:author]} ]
    #
    # Into this:
    #
    #   {
    #     tags: {},
    #     images: {
    #       comments: {}
    #     }
    #     reviews: {}
    #     }
    #   }
    #
    def self.flatten(hash)
      result = []
      hash.each do |k, v|
        if v.keys.size == 0
          result << k.to_sym
        else
          result << { "#{k}".to_sym => flatten(v) }
        end
      end
      result
    end

  end
end