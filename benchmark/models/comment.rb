class Comment
  attr_reader :id, :author, :content
  def initialize(id:, author:, content:)
    @id = id
    @author = author
    @content = content
  end

  def self.model_name
    name
  end

  def read_attribute_for_serialization(attr)
    public_send(attr)
  end
end
