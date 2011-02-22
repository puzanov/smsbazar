class SearchController < ApplicationController
  def index
    q = params[:q]
    if q.present?
      @advs = Adv.search(q.gsub(" ", " | "), :match_mode => :extended)
    end
  end
end
