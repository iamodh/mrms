require "test_helper"

class Admin::RegistrationsTest < ActionDispatch::IntegrationTest
  setup do
    admin_login
  end

  test "default order is newest first" do
    get admin_registrations_path

    assert_response :success
    assert_select "tbody tr" do |rows|
      names = rows.map { |row| row.at_css("td:first-child").text.strip }
      assert_equal [ "김달리", "이영희", "홍길동" ], names
    end
  end

  test "sort by name ascending" do
    get admin_registrations_path(sort: "name_asc")

    assert_select "tbody tr" do |rows|
      names = rows.map { |row| row.at_css("td:first-child").text.strip }
      assert_equal [ "김달리", "이영희", "홍길동" ], names
    end
  end

  test "sort by name descending" do
    get admin_registrations_path(sort: "name_desc")

    assert_select "tbody tr" do |rows|
      names = rows.map { |row| row.at_css("td:first-child").text.strip }
      assert_equal [ "홍길동", "이영희", "김달리" ], names
    end
  end

  test "filter by course" do
    five_km = courses(:five_km)

    get admin_registrations_path(course_id: five_km.id)

    assert_select "tbody tr", count: 2
    assert_select "td", text: "홍길동"
    assert_select "td", text: "이영희"
    assert_select "td", text: "김달리", count: 0
  end

  test "filter by status applied" do
    get admin_registrations_path(status: "applied")

    assert_select "tbody tr", count: 2
    assert_select "td", text: "홍길동"
    assert_select "td", text: "김달리"
    assert_select "td", text: "이영희", count: 0
  end

  test "filter by status canceled" do
    get admin_registrations_path(status: "canceled")

    assert_select "tbody tr", count: 1
    assert_select "td", text: "이영희"
  end

  test "no status filter shows all registrations" do
    get admin_registrations_path

    assert_select "tbody tr", count: 3
  end

  test "page displays sort links and filter controls" do
    get admin_registrations_path

    assert_select "a[href*='sort=name_asc']"
    assert_select "a[href*='sort=name_desc']"
    assert_select "select[name='course_id']"
    assert_select "select[name='status']"
  end

  test "dashboard has link to registrations page" do
    get admin_root_path

    assert_select "a[href='#{admin_registrations_path}']"
  end
end
