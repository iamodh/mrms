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

  def render_not_found
    render "admin/errors/not_found", status: :not_found
  end
end
