class HomeController < ApplicationController
  def index
    @f = 1
    @p = params[:status]
  end
end
