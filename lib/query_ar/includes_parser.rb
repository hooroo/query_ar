module IncludesParser

  def self.from_params(params)

    includes_hash = {}
    include_str = params[:include] || ''
    include_paths = include_str.split(',').map { |include_path| include_path.split('.') }

    include_paths.each do |path|
      current_hash = includes_hash
      path.each do |token|
        current_hash[token] ||= {}
        current_hash = current_hash[token]
      end
    end

    flatten(includes_hash)
  end

  private

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
