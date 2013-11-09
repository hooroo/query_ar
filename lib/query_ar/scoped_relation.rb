class ScopedRelation

  attr_accessor :model_class, :scopes

  def initialize(model_class, scopes = {})
    @model_class = model_class
    @scopes = scopes
  end

  def scoped
    scopes.inject(model_class.all) do | scope_memo, (scope_name, arg) |
      scope_memo.send(scope_name, arg)
    end
  end

end