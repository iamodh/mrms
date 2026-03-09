class Admin::DashboardController < Admin::BaseController
  def show
    @race = Race.order(event_date: :desc).first
    @courses = @race.courses.order(:start_time)
  end
end
