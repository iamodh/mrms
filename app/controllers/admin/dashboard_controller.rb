class Admin::DashboardController < ApplicationController
  before_action :require_admin

  def show
  end

  private

  def require_admin
    redirect_to admin_login_path unless session[:admin]
  end
end
