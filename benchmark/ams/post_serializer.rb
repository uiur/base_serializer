module Ams
  class CommentSerializer < ActiveModel::Serializer
    attributes :id, :author, :content
  end

  class PostSerializer < ActiveModel::Serializer
    attributes :id,
              :title, :body,
              :created_at, :updated_at

    has_many :comments, serializer: ::Ams::CommentSerializer
  end
end
