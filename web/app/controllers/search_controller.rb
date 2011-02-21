class SearchController < ApplicationController
  def index
    q = params[:q]
    if q.present?
      @advs = Adv.search q
      
      #@size = Adv.search(q).size
      #@advs = Adv.any_of({ :content => /(.*?)#{q}(.*?)/is }, { :city => q })
    end
  end
end
