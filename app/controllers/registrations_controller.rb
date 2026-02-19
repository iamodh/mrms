class RegistrationsController < ApplicationController
  def new
    @course = Course.find(params[:course_id])
    @registration = @course.registrations.new
  end

  def create
    @course = Course.find(params[:course_id])
    @registration = @course.registrations.new(registration_params)

    if @registration.save
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:registration).permit(:name, :phone_number, :birth_date, :gender, :address)
  end
end
