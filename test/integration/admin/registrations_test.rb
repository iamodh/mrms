require "test_helper"

class Admin::RegistrationsTest < ActionDispatch::IntegrationTest
  setup do
    admin_login
  end

  test "default order is newest first" do
    get admin_registrations_path

    assert_response :success
    assert_select "tr.registration-row" do |rows|
      names = rows.map { |row| row.at_css("td.registration-name").text.strip }
      assert_equal ["김달리", "이영희", "홍길동"], names
    end
  end
end
