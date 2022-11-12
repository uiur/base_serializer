# BaseSerializer

base_serializer is a JSON object presenter (like active_model_serializers).

The implementation is one file (< 200 lines). It's easy to customize.

base_serializer doesn't have as many features as active_model_serializers, but the small set of features are enough to build a JSON API.

In a simple [benchmark](benchmark/), base_serializer is ~8x faster than active_model_serializers.

It's can be combined with Rails and any Ruby web frameworks.
## Usage
`serialize` method is used to render JSON serializable hash.

For example,

```ruby
class ProductSerializer
  include ::BaseSerializer
  field :id, :name, :price, :created_at
end

Product = Struct.new(:id, :name, :price, :created_at, keyword_init: true)
product =
  Product.new(
    id: 1,
    name: "foo",
    price: 12.3,
    created_at: Time.now
  )

pp ProductSerializer.serialize(product)
#=> {:id=>1, :name=>"foo", :price=>12.3, :created_at=>"2022-10-31T22:08:10.573+09:00"}

# `serialize` can take array of objects as an argument
# It renders array of serialized hash
pp ProductSerializer.serialize([product])
#=> [{:id=>1, :name=>"foo", :price=>12.3, :created_at=>"2022-11-12T15:29:33.820+09:00"}]

# It can render only selected fields
pp ProductSerializer.serialize([product], fields: [:id, :name])
#=> [{:id=>1, :name=>"foo"}]
```

### Association
It can render nested objects with has_many or belongs_to associations.

base_serializer just uses the `field` method to define associations.

```ruby
class CommentSerializer
  include ::BaseSerializer
  field :id, :content
end

class PostSerializer
  include ::BaseSerializer
  field :id, :title
  field :comments, serializer: CommentSerializer
end

post  =
  OpenStruct.new(
    id: 1,
    title: "foo",
    comments: [
      OpenStruct.new(id: 2, content: "bar"),
    ]
  )

pp PostSerializer.serialize(post)
#=> {:id=>1, :title=>"foo", :comments=>[{:id=>2, :content=>"bar"}]}

# Fields of nested object like post.comments can be selected
pp PostSerializer.serialize(post, fields: [
  :id,
  :title,
  comments: [:id]
])
#=> {:id=>1, :title=>"foo", :comments=>[{:id=>2}]}
```

### Optional fields
`default: false` option can be used to mark a field as optional.

Optional fields are rendered only when fields are specified in `fields: [..]`.

```ruby
class CommentSerializer
  include ::BaseSerializer
  field :id, :content
end

class PostSerializer
  include ::BaseSerializer
  field :id, :title  # default: true (if not specified)
  field :content, default: false
  field :comments, serializer: CommentSerializer, default: false
end

post  =
  OpenStruct.new(
    id: 1,
    title: "foo",
    content: 'foo content',
    comments: [
      OpenStruct.new(id: 2, content: "bar"),
    ]
  )

# It renders only default fields (id and title) when fields are not specified
pp PostSerializer.serialize(post)
#=> {:id=>1, :title=>"foo"}

# Optional fields are rendered when they are selected.
pp PostSerializer.serialize(post, fields: [:id, :title, :content, :comments])
#=> {:id=>1, :title=>"foo", :content=>"foo content", :comments=>[{:id=>2, :content=>"bar"}]}

pp PostSerializer.serialize(post, fields: [
  :*,  # :* means all of default fields.
  :comments
])
#=> {:id=>1, :title=>"foo", :comments=>[{:id=>2, :content=>"bar"}]}
```

### Defining methods in serializer
Defining or overriding methods is allowed.

```ruby
class ProductSerializer
  include ::BaseSerializer
  field :id, :name

  def id
    # The source object can be accessed by `object`
    "product-#{object.id}"
  end
end

Product = Struct.new(:id, :name, keyword_init: true)
product =
  Product.new(
    id: 1,
    name: "foo",
  )

pp ProductSerializer.serialize(product)
#=> {:id=>"product-1", :name=>"foo"}
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'base_serializer', github: 'uiur/base_serializer', branch: 'main'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install base_serializer

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/uiur/base_serializer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/uiur/base_serializer/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BaseSerializer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/uiur/base_serializer/blob/main/CODE_OF_CONDUCT.md).
