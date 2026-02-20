class RegistrationsController < ApplicationController
  def new
    @course = Course.find(params[:course_id])
    @registration = @course.registrations.new
  end

  def create
    @course = Course.find(params[:course_id])
    @registration = @course.create_registration!(registration_params)
    redirect_to root_path
  rescue Course::CapacityExceededError => e
    redirect_to new_course_registration_path(@course), alert: e.message
  rescue ActiveRecord::RecordInvalid => e
    @registration = e.record
    render :new, status: :unprocessable_entity
  end

  private

  def registration_params
    params.require(:registration).permit(:name, :phone_number, :birth_date, :gender, :address)
  end
end
