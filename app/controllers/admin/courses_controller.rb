class Admin::CoursesController < Admin::BaseController
  def edit
    @course = Course.find(params[:id])
  end

  def update
    @course = Course.find(params[:id])
    if @course.update(course_params)
      redirect_to admin_root_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def course_params
    params.require(:course).permit(:capacity)
  end
end
