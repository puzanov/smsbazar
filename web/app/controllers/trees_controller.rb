class TreesController < ApplicationController
  # GET /trees
  # GET /trees.xml
  def index
    @trees = Tree.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @trees }
    end
  end

  # GET /trees/1
  # GET /trees/1.xml
  def show
    @tree = Tree.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @tree }
    end
  end

  # GET /trees/new
  # GET /trees/new.xml
  def new
    @tree = Tree.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @tree }
    end
  end

  # GET /trees/1/edit
  def edit
    @tree = Tree.find(params[:id])
  end

  # POST /trees
  # POST /trees.xml
  def create
    @tree = Tree.new(params[:tree])

    respond_to do |format|
      if @tree.save
        format.html { redirect_to(@tree, :notice => 'Tree was successfully created.') }
        format.xml  { render :xml => @tree, :status => :created, :location => @tree }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @tree.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /trees/1
  # PUT /trees/1.xml
  def update
    @tree = Tree.find(params[:id])

    respond_to do |format|
      if @tree.update_attributes(params[:tree])
        format.html { redirect_to(@tree, :notice => 'Tree was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tree.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /trees/1
  # DELETE /trees/1.xml
  def destroy
    @tree = Tree.find(params[:id])
    @tree.destroy

    respond_to do |format|
      format.html { redirect_to(trees_url) }
      format.xml  { head :ok }
    end
  end
end
