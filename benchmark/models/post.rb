class Post
  attr_reader :id, :title, :body, :created_at, :updated_at, :comments
  def initialize(id:, title:, body:, created_at:, updated_at:, comments:)
    @id = id
    @title = title
    @body = body
    @created_at = created_at
    @updated_at = updated_at
    @comments = comments
  end

  def self.model_name
    name
  end

  def read_attribute_for_serialization(attr)
    public_send(attr)
  end
end
