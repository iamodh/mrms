class Admin::BaseController < ApplicationController
  before_action :require_admin

  private

  def require_admin
    redirect_to admin_login_path unless session[:admin]
  end
end
