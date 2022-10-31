# BaseSerializer

base_serializer is a JSON object presenter (like active_model_serializers).

The implementation is one file (< 200 lines).

## Usage

```ruby
class ProductSerializer
  include ::BaseSerializer
  field :id, :name, :price, :created_at
end

product =
  Product.new(
    id: 1,
    name: "foo",
    price: 12.3,
    created_at: Time.now
  )

ProductSerializer.serialize(product)
#=> {:id=>1, :name=>"foo", :price=>12.3, :created_at=>"2022-10-31T22:08:10.573+09:00"}

```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'base_serializer'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install base_serializer

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/base_serializer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/base_serializer/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BaseSerializer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/base_serializer/blob/main/CODE_OF_CONDUCT.md).
