require 'spec_helper'
require 'query_ar'

describe IncludesParser do

  describe 'from params' do
    let(:params) { {include: 'a,a.b,a.b.c,b,c'} }

    let(:includes) { IncludesParser.from_params(params) }

    it 'creates single level includes' do
      expect(includes).to include :b
      expect(includes).to include :c
    end

    it 'creates nested includes' do
      expect(includes).to include({a: [{b: [:c]}]})
    end

    it 'creates same structure when implicit parts of the path are removed' do
      simplified_params =  { include: 'a.b.c,b,c' }
      simplified_includes =  IncludesParser.from_params(simplified_params)
      expect(includes).to eql simplified_includes
    end
  end

end