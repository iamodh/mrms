class RegistrationsController < ApplicationController
  def new
    @course = Course.find(params[:course_id])
    @registration = @course.registrations.new
  end

  def create
    @course = Course.find(params[:course_id])

    unless @course.available?
      alert = @course.race.registration_closed? ? "신청 기간이 종료되었습니다." : "선택하신 코스의 정원이 마감되었습니다."
      redirect_to new_course_registration_path(@course), alert: alert
      return
    end

    @registration = @course.create_registration!(registration_params)
    redirect_to root_path
  rescue Course::RegistrationClosedError, Course::CapacityExceededError => e
    redirect_to new_course_registration_path(@course), alert: e.message
  rescue ActiveRecord::RecordNotUnique
    redirect_to new_course_registration_path(@course),
      alert: "이미 동일한 이름과 전화번호로 신청된 내역이 있습니다."
  rescue ActiveRecord::RecordInvalid => e
    @registration = e.record
    render :new, status: :unprocessable_entity
  end

  private

  def registration_params
    params.require(:registration).permit(:name, :phone_number, :birth_date, :gender, :address)
  end
end
