class Admin::DashboardController < Admin::BaseController
  def show
    @courses = @race.courses.order(:id)
  end
end
