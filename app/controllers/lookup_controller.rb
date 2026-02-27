class LookupController < ApplicationController
  def new
  end

  def create
    @registration = Registration.find_by(
      confirmation_code: params[:confirmation_code],
      name: params[:name]
    )

    if @registration
      render :show
    else
      redirect_to lookup_path, alert: "신청 내역을 찾을 수 없습니다."
    end
  end
end
