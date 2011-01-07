class AdvsController < ApplicationController
  # GET /advs
  # GET /advs.xml
  def index
    @advs = Adv.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @advs }
    end
  end

  # GET /advs/1
  # GET /advs/1.xml
  def show
    @adv = Adv.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @adv }
    end
  end

  # GET /advs/new
  # GET /advs/new.xml
  def new
    @adv = Adv.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @adv }
    end
  end

  # GET /advs/1/edit
  def edit
    @adv = Adv.find(params[:id])
  end

  # POST /advs
  # POST /advs.xml
  def create
    @adv = Adv.new(params[:adv])

    respond_to do |format|
      if @adv.save
        format.html { redirect_to(@adv, :notice => 'Adv was successfully created.') }
        format.xml  { render :xml => @adv, :status => :created, :location => @adv }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @adv.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /advs/1
  # PUT /advs/1.xml
  def update
    @adv = Adv.find(params[:id])

    respond_to do |format|
      if @adv.update_attributes(params[:adv])
        format.html { redirect_to(@adv, :notice => 'Adv was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @adv.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /advs/1
  # DELETE /advs/1.xml
  def destroy
    @adv = Adv.find(params[:id])
    @adv.destroy

    respond_to do |format|
      format.html { redirect_to(advs_url) }
      format.xml  { head :ok }
    end
  end
end
