# frozen_string_literal: true

require 'ostruct'

RSpec.describe BaseSerializer do
  describe 'VERSION' do
    it "has a version number" do
      expect(BaseSerializer::VERSION).not_to be nil
    end
  end

  describe '.serialize' do
    describe 'flat structure' do
      class self::ProductSerializer
        include ::BaseSerializer
        field :id, :name, :price, :created_at
      end

      Product = Struct.new(*self::ProductSerializer.fields.keys, keyword_init: true)

      let(:product) do
        Product.new(
          id: 1,
          name: "foo",
          price: 12.3,
          created_at: Time.now
        )
      end

      context 'default' do
        it 'returns hash with all fields' do
          expect(self.class::ProductSerializer.serialize(product)).to match({
            id: 1,
            name: 'foo',
            price: 12.3,
            created_at: product.created_at.iso8601(3)
          })
        end
      end

      context 'select fields' do
        it 'returns hash with selected fields' do
          expect(self.class::ProductSerializer.serialize(product, fields: [:id, :name])).to match(
            id: 1,
            name: 'foo',
          )
        end
      end

      context 'input object is array' do
        it 'returns array of hashes' do
          expect(self.class::ProductSerializer.serialize([product])).to match([
            {
              id: 1,
              name: 'foo',
              price: 12.3,
              created_at: product.created_at.iso8601(3)
            }
          ])
        end
      end
    end

    describe 'nested structure' do
      class self::ProductSerializer
        include ::BaseSerializer

        class ProductImageSerializer
          include ::BaseSerializer
          field :id, :url
        end

        field :id
        relation :product_images, serializer: ProductImageSerializer
      end

      let(:product) do
        OpenStruct.new({
          id: 1,
          product_images: [
            OpenStruct.new(id: 2, url: 'http://example.com/image.png')
          ]
        })
      end

      context 'default' do
        it 'returns hash with fields except relations' do
          expect(self.class::ProductSerializer.serialize(product)).to match({
            id: 1,
          })
        end
      end

      context 'relation fields are selected' do
        it 'returns hash with relation fields' do
          expect(self.class::ProductSerializer.serialize(product, fields: [:*, :product_images])).to match({
            id: 1,
            product_images: [
              {
                id: 2,
                url: 'http://example.com/image.png'
              }
            ]
          })
        end
      end
    end
  end
end
