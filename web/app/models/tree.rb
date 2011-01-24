class Tree
  include Mongoid::Document
  include Mongoid::Tree
  include Mongoid::Tree::Traversal
  field :name, :type => String
  field :tags, :type => Hash
end
