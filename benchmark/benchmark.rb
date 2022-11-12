require 'rails/all'
Bundler.require(*Rails.groups)

ActiveRecord::Base.logger = nil
ActiveModelSerializers.logger = nil

require_relative './models/post'
require_relative './models/comment'
require_relative './ams/post_serializer'
require_relative './base/post_serializer'

def build_comment
  Comment.new(
    id: SecureRandom.uuid,
    author: SecureRandom.alphanumeric(10),
    content: SecureRandom.alphanumeric(10),
  )
end

def build_post(comment_size: 0)
  Post.new(
    id: SecureRandom.uuid,
    title: SecureRandom.alphanumeric(10),
    body: SecureRandom.alphanumeric(10),
    created_at: Time.current,
    updated_at: Time.current,
    comments: comment_size.times.map { build_comment }
  )
end

def serialize_ams(data)
  ActiveModelSerializers::SerializableResource.new(
    data,
    include: 'comments',
    serializer: ActiveModel::Serializer::CollectionSerializer,
    each_serializer: ::Ams::PostSerializer
  ).as_json
end

def serialize_base_serializer(data)
  Base::PostSerializer.serialize(data)
end

data = 10.times.map { build_post(comment_size: 10) }

unless serialize_ams(data).to_json == serialize_base_serializer(data).to_json
  raise 'json mismatch'
end

%i[ips memory].each do |bench|
  Benchmark.send(bench) do |x|
    x.config(time: 10, warmup: 5, stats: :bootstrap, confidence: 95) if x.respond_to?(:config)

    x.report('ams') do
      serialize_ams(data)
    end

    x.report('base_serializer') do
      serialize_base_serializer(data)
    end

    x.compare!
  end
end
