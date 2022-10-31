# frozen_string_literal: true

RSpec.describe BaseSerializer do
  it "has a version number" do
    expect(BaseSerializer::VERSION).not_to be nil
  end

  context 'flat structure' do
    class ProductSerializer
      include ::BaseSerializer
      field :id, :name, :price, :created_at
    end

    Product = Struct.new(*ProductSerializer.fields.keys, keyword_init: true)

    let(:product) do
      Product.new(
        id: 1,
        name: "foo",
        price: 12.3,
        created_at: Time.now
      )
    end

    it do
      pp ProductSerializer.serialize(product)
      pp ProductSerializer.serialize(product, fields: [:id, :name])
    end
  end
end
