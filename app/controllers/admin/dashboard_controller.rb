class Admin::DashboardController < ApplicationController
  before_action :require_admin

  def show
    @race = Race.order(event_date: :desc).first
    @courses = @race.courses.order(:start_time)
  end

  private

  def require_admin
    redirect_to admin_login_path unless session[:admin]
  end
end
