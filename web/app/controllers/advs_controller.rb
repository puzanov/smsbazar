class AdvsController < ApplicationController
  def index
    WillPaginate::ViewHelpers.pagination_options[:previous_label] = "&#8592;&nbsp;Назад"
    WillPaginate::ViewHelpers.pagination_options[:next_label] = "Далее&nbsp;&#8594;"
    @advs = Adv.find(:all).desc(:ctime).paginate :page => params[:page], :per_page => 5
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
    @advs = Adv.where(:city => params[:city_name]).desc(:ctime).paginate :page => params[:page], :per_page => 5
    render :index
  end
end
