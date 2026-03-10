class Admin::RegistrationsController < Admin::BaseController
  def index
    @registrations = @race.registrations.includes(:course).order(created_at: :desc)
  end
end
