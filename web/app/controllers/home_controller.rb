require 'menu_manager'
require 'rubygems'
require 'mongoid/tree'

class HomeController < ApplicationController
  attr_accessor :menu_manager
  
  def index
    id = params[:id]
    @menu_manager = MenuManager.new
    if id.present?
      node_id = id
    else
      if Tree.root.nil?
        Tree.new(:name => "root").save
      end
      node_id = Tree.root.id.to_s      
    end

    @bread_crumps = Array.new
    @current_node = @menu_manager.get_node(node_id)
    @current_node.parent_ids.each do |parent_id|
      n = Tree.find(parent_id)
      @bread_crumps << n
    end
    @cats = @menu_manager.get_particular_menu node_id

    if @current_node.leaf?
      @advs = @menu_manager.get_advs @current_node
    end

  end

  def add_category
    parent_id = params[:parent_id]
    name = params[:name]
    if parent_id == ""
      parent_id = Tree.root.id.to_s
    end
    tree = Tree.new
    tree.name = name
    tree.parent_id = parent_id
    tree.save
    redirect_to :back
  end

  def delete_category
    id = params[:id]
    tree = Tree.find(id)
    parent_id = tree.parent_id
    tree.destroy
    redirect_to :action => "index", :id => parent_id.to_s
  end

  def edit_category
    id = params[:id]
    name = params[:update_value]
   
    @node = Tree.find(id)
    @node.name = name
    @node.save

    render :text => name
  end

  def add_adv
    node_id = params[:parent_id]
    content = params[:content]

    adv = Adv.new
    adv.node_id = node_id
    adv.content = content
    adv.save
    
    redirect_to :back
  end

end
