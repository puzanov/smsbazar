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
end
