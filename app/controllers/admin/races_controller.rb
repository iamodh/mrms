class Admin::RacesController < Admin::BaseController
  def edit
    @race = Race.order(event_date: :desc).first
  end

  def update
    @race = Race.order(event_date: :desc).first
    if @race.update(race_params)
      redirect_to admin_root_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def race_params
    params.require(:race).permit(:registration_deadline)
  end
end
