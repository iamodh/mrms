class HomeController < ApplicationController
  def show
    @race = Race.first!
    @courses = @race.courses.where("capacity > 0")
  end
end
