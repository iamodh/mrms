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

  def cancel
    registration = Registration.find_by!(
      confirmation_code: params[:confirmation_code],
      name: params[:name]
    )

    registration.cancel!
    redirect_to lookup_path, notice: "신청이 취소되었습니다."
  rescue ActiveRecord::RecordNotFound
    redirect_to lookup_path, alert: "신청 내역을 찾을 수 없습니다."
  rescue Registration::NotCancelableError => e
    redirect_to lookup_path, alert: e.message
  end
end
