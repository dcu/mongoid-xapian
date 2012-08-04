class BlogPost
  include Mongoid::Document
  include Mongoid::Timestamps
  include MongoidXapian

  field :title
  field :body
  field :language

  fti :title, :body, :created_at, :updated_at
end
