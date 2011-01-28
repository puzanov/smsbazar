class Adv
  include Mongoid::Document
  field :phone, :type => String
  field :content, :type => String
  field :node_id, :type => String
  field :city, :type => String
  field :price, :type => Integer
end
