class Admin::RegistrationsController < Admin::BaseController
  SORT_OPTIONS = {
    "name_asc" => { name: :asc },
    "name_desc" => { name: :desc }
  }.freeze

  def index
    order = SORT_OPTIONS.fetch(params[:sort], { created_at: :desc })
    @registrations = @race.registrations.includes(:course).order(order)
  end
end
