class RegistrationsController < ApplicationController
  def new
    @course = Course.find(params[:course_id])
    @registration = @course.registrations.new
  end
end
