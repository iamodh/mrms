class HomeController < ApplicationController
  def show
    @race = Race.upcoming.first!
    @courses = @race.courses.where("capacity > 0")
  end
end
