require 'query_ar/includes'
require 'pry'

module QueryAr
  describe Includes do

    context 'when constructed with no value' do
      let(:includes) { Includes.new }

      it 'is empty, not present and blank' do
        expect(includes).to be_empty
        expect(includes).to be_blank
        expect(includes).to_not be_present
      end
    end

    describe '.from_string' do

      let(:string)   { 'a,a.b,a.b.c,b,c' }
      let(:includes) { Includes.from_string(string) }

      it 'creates single level includes' do
        expect(includes).to include :b
        expect(includes).to include :c
      end

      it 'creates nested includes' do
        expect(includes).to include({a: [{b: [:c]}]})
      end

      it 'creates same structure when implicit parts of the path are removed' do
        simplified_params = 'a.b.c,b,c'
        simplified_includes =  Includes.from_string(simplified_params)
        expect(includes).to eq simplified_includes
      end

      context 'when a nil or empty string is provided' do

        it 'returns a new includes' do
          expect(Includes.from_string(nil)).to eq Includes.new
          expect(Includes.from_string('')).to eq Includes.new
        end
      end
    end

    describe "#to_s" do

      it "converts to dot-notation specified by the JSON API spec, sorted alphabetically" do
        includes = Includes.new(:reviews, {images: [{comments: [:author]}]}, :hashtags)
        expect(includes.to_s).to eq 'hashtags,images,images.comments,images.comments.author,reviews'

        includes = Includes.new(:hashtags, {images: [{comments: [:author, :rating]}]}, :reviews)
        expect(includes.to_s).to eq 'hashtags,images,images.comments,images.comments.author,images.comments.rating,reviews'
      end
    end

    describe 'equality' do
      it 'works as expected' do
        one = [ :tags, {images: [:comments]}, {reviews: [:author]} ]
        two = [ :tags, {images: [:comments]}, {reviews: [:author]} ]
        expect(Includes.new(*one)).to eq Includes.new(*two)

        one = [ {reviews: [:author]}, :tags, {images: [:comments]} ]
        two = [ :tags, {images: [:comments]}, {reviews: [:author]} ]
        expect(Includes.new(*one)).to eq Includes.new(*two)

        one = [ :tags, {images: [:comments]}, {reviews: [:author]} ]
        two = [ :tags, {images: [:comments]}, :reviews ]
        expect(Includes.new(*one)).to_not eq Includes.new(*two)
      end
    end

    describe '#&' do

      let(:relations) { [ :tags, {images: [:comments]}, {reviews: [:author]} ] }
      let(:includes)  { Includes.new(*relations) }

      let(:scenarios) do
        [
          {
            includes: [ {images: [:comments]} ],
            other:    [ {images: [:comments]} ],
            expected: [ {images: [:comments]} ]
          },
          {
            includes: [ {images: [:comments, :hashtags]} ],
            other:    [ {images: [:comments]} ],
            expected: [ {images: [:comments]} ]
          },
          {
            includes: [ {images: [:comments]} ],
            other:    [ {images: [:comments, :hashtags]} ],
            expected: [ {images: [:comments]} ]
          },
          {
            includes: [ :reviews, {images: [{comments: [:author]}]}, :hashtags ],
            other:    [ :reviews, {images: [{comments: [:author]}]}, :hashtags ],
            expected: [ :reviews, {images: [{comments: [:author]}]}, :hashtags ]
          },
          {
            includes: [ :reviews, {images: [{comments: [:author]}]} ],
            other:    [ :reviews, {images: [ :comments ]} ],
            expected: [ :reviews, {images: [ :comments ]} ]
          },
          {
            includes: [ :reviews, {images: [ :comments ]} ],
            other:    [ :reviews, {images: [{comments: [:author]}]} ],
            expected: [ :reviews, {images: [ :comments ]} ]
          },
          {
            includes: [ :reviews, {images: [{comments: [:author]}]} ],
            other:    [ :reviews, :images ],
            expected: [ :reviews, :images ]
          },
          {
            includes: [ :reviews, {images: [{comments: [:author]}]} ],
            other:    [ :reviews, :images, :hashtags ],
            expected: [ :reviews, :images ]
          }
        ]
      end

      it 'reuturns a new Includes as a deep intersection between two Includes' do
        scenarios.each do |scenario|
          includes = scenario[:includes]
          other    = scenario[:other]
          expected = scenario[:expected]

          intersection = Includes.new(*includes) & Includes.new(*other)
          expect(intersection).to eq Includes.new(*expected)
        end
      end

    end

  end
end