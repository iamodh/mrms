class Admin::DashboardController < Admin::BaseController
  def show
    @courses = @race.courses.order(:start_time)
  end
end
