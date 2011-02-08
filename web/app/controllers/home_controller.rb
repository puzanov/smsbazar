require 'menu_manager'

class HomeController < ApplicationController
  attr_accessor :menu_manager
  
  def index
    id = params[:id]
    @menu_manager = MenuManager.new
    if id.present?
      node_id = id
    else
      node_id = Tree.root.id.to_s      
    end
    @cats = @menu_manager.get_particular_menu node_id
  end
end
