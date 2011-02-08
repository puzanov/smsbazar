require 'menu_manager'

class HomeController < ApplicationController
  attr_accessor :menu_manager
  
  def index
    @menu_manager = MenuManager.new
    root_id = Tree.root.id.to_s      
    @cats = @menu_manager.get_particular_menu root_id
  end
end
