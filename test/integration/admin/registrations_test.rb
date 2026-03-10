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

  test "sort by name ascending" do
    get admin_registrations_path(sort: "name_asc")

    assert_select "tr.registration-row" do |rows|
      names = rows.map { |row| row.at_css("td.registration-name").text.strip }
      assert_equal ["김달리", "이영희", "홍길동"], names
    end
  end

  test "sort by name descending" do
    get admin_registrations_path(sort: "name_desc")

    assert_select "tr.registration-row" do |rows|
      names = rows.map { |row| row.at_css("td.registration-name").text.strip }
      assert_equal ["홍길동", "이영희", "김달리"], names
    end
  end
end
