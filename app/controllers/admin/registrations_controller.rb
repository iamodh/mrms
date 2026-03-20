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

    respond_to do |format|
      format.html
      format.xlsx { send_registrations_xlsx }
    end
  end

  private

  def send_registrations_xlsx
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: "신청자목록") do |sheet|
      sheet.add_row %w[이름 생년월일 성별 전화번호 주소 코스 상태 확인코드 신청일]
      @registrations.each do |r|
        sheet.add_row [
          r.name, r.birth_date.to_s, r.gender_label,
          r.formatted_phone_number, r.address, r.course.name,
          r.status_label, r.confirmation_code,
          r.created_at.strftime("%Y-%m-%d %H:%M")
        ]
      end
    end
    send_data package.to_stream.read,
      filename: "#{xlsx_filename}.xlsx",
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end

  def xlsx_filename
    parts = [ @race.name, "신청자목록" ]
    parts << Course.find(params[:course_id]).name if params[:course_id].present?
    parts << Registration::STATUS_LABELS[params[:status]] if params[:status].in?(ALLOWED_STATUSES)
    parts << xlsx_sort_label
    parts << Date.current.strftime("%Y%m%d")
    parts.join("_")
  end

  SORT_LABELS = { "newest" => "최신순", "name_asc" => "이름순", "name_desc" => "이름역순" }.freeze

  def xlsx_sort_label
    SORT_LABELS.fetch(params[:sort], "최신순")
  end
end
