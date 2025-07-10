class AnalyticsController < ApplicationController
  before_action :require_authentication
  
  def index
    @period = params[:period] || 'week'
    @analytics = Current.user.analytics_data(@period.to_sym)
    
    respond_to do |format|
      format.html
      format.json { render json: @analytics }
    end
  end
end
