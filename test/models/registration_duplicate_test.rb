require "test_helper"

class RegistrationDuplicateTest < ActiveSupport::TestCase
  test "concurrent duplicate registrations with same info allows only 1 success" do
    course = courses(:ten_km)
    params = {
      name: "김철수",
      phone_number: "01099998888",
      birth_date: "1985-03-15",
      gender: "male",
      address: "부산시 해운대구"
    }
    results = Concurrent::Array.new

    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          course.create_registration!(params.dup)
          results << :success
        rescue ActiveRecord::RecordNotUnique
          results << :duplicate
        rescue ActiveRecord::RecordInvalid => e
          if e.message.include?("이미 동일한 이름과 전화번호로")
            results << :duplicate
          else
            raise
          end
        end
      end
    end

    threads.each(&:join)

    assert_equal 1, results.count(:success)
    assert_equal 1, results.count(:duplicate)
  end
end
