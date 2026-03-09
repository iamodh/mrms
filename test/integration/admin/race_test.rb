require "test_helper"

class Admin::RaceTest < ActionDispatch::IntegrationTest
  test "update registration_deadline persists to DB" do
    admin_login
    race = races(:marathon_2026)
    new_deadline = 1.month.from_now

    patch admin_race_path, params: { race: { registration_deadline: new_deadline } }

    assert_redirected_to admin_root_path
    assert_in_delta new_deadline, race.reload.registration_deadline, 1.second
  end
end
