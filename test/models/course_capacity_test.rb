require "test_helper"

class CourseCapacityTest < ActiveSupport::TestCase
  test "concurrent registrations with capacity 1 allows only 1 success" do
    course = courses(:one_slot)
    results = Concurrent::Array.new

    threads = 2.times.map do |i|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          course.create_registration!(
            name: "신청자#{i}",
            phone_number: "0101234000#{i}",
            birth_date: "1990-01-01",
            gender: "male",
            address: "서울시 강남구"
          )
          results << :success
        rescue Course::CapacityExceededError
          results << :capacity_exceeded
        end
      end
    end

    threads.each(&:join)

    assert_equal 1, results.count(:success)
    assert_equal 1, results.count(:capacity_exceeded)
    assert_equal 1, course.registrations.where(status: "applied").count
  end
end
