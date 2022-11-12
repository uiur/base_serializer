module Base
  class CommentSerializer
    include ::BaseSerializer
    field :id
    field :author
    field :content
  end

  class PostSerializer
    include ::BaseSerializer
    field :id
    field :title
    field :body
    field :created_at
    field :updated_at
    field :comments, serializer: ::Base::CommentSerializer
  end
end
