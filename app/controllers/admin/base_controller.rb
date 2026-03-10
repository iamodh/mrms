class Admin::BaseController < ApplicationController
  before_action :require_admin
  before_action :set_race

  private

  def require_admin
    redirect_to admin_login_path unless session[:admin]
  end

  def set_race
    @race = Race.latest
  end
end
