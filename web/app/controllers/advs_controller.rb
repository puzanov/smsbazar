class AdvsController < ApplicationController
  def index
    @advs = Adv.find(:all).desc(:ctime)   
  end

  def delete
    id = params[:id]
    adv = Adv.find id
    adv.destroy
    redirect_to :back
  end

  def edit
    id = params[:id]
    @adv = Adv.find id
  end

  def save
    adv = Adv.find params[:id]
    adv.content = params[:content]
    adv.city = params[:city]
    adv.price = params[:price]
    adv.save
    redirect_to "/advs/edit/" + params[:id]
  end

  def by_city
    @advs = Adv.where(:city => params[:city_name]).desc(:ctime)
    render :index
  end
end
