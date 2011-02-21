class Adv
  include Mongoid::Document
  include Mongoid::Search

  field :phone, :type => String
  field :content, :type => String
  field :node_id, :type => String
  field :city, :type => String
  field :price, :type => Integer
  field :ctime, :type => Integer

  index :content
  index :city

  search_in :content, :city, { :match => :any }
end
