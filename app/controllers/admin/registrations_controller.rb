class Admin::RegistrationsController < Admin::BaseController
  SORT_OPTIONS = {
    "name_asc" => { name: :asc },
    "name_desc" => { name: :desc }
  }.freeze

  def index
    order = SORT_OPTIONS.fetch(params[:sort], { created_at: :desc })
    scope = @race.registrations.includes(:course)
    scope = scope.where(course_id: params[:course_id]) if params[:course_id].present?
    @registrations = scope.order(order)
  end
end
