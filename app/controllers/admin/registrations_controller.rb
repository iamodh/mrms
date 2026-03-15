class Admin::RegistrationsController < Admin::BaseController
  SORT_OPTIONS = {
    "newest" => { created_at: :desc },
    "name_asc" => { name: :asc },
    "name_desc" => { name: :desc }
  }.freeze

  ALLOWED_STATUSES = %w[applied canceled refunded].freeze

  def index
    order = SORT_OPTIONS.fetch(params[:sort], { created_at: :desc })
    scope = @race.registrations.includes(:course)
    scope = scope.where(course_id: params[:course_id]) if params[:course_id].present?
    scope = scope.where(status: params[:status]) if params[:status].in?(ALLOWED_STATUSES)
    @registrations = scope.order(order)
    @courses = @race.courses.order(:id)
  end
end
