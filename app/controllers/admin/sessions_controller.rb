class Admin::SessionsController < ApplicationController
  def new
  end

  def create
    if params[:id] == ENV["ADMIN_ID"] && params[:password] == ENV["ADMIN_PW"]
      session[:admin] = true
      redirect_to admin_root_path, notice: "로그인 성공"
    else
      flash.now[:alert] = "아이디 또는 비밀번호가 올바르지 않습니다."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:admin)
    redirect_to admin_login_path, notice: "로그아웃 되었습니다."
  end
end
