require "test_helper"

class Admin::DashboardTest < ActionDispatch::IntegrationTest
  test "unauthenticated access to admin root redirects to login" do
    get admin_root_path

    assert_redirected_to admin_login_path
  end

  test "authenticated access to admin root succeeds" do
    admin_login

    get admin_root_path

    assert_response :success
  end

  test "dashboard displays race info" do
    admin_login

    get admin_root_path

    assert_select "h1", text: "서울마라톤 2026"
    assert_select "p", text: /서울 여의도공원/
  end

  test "dashboard displays course list with capacity and applied count" do
    admin_login

    get admin_root_path

    assert_select "table" do
      assert_select "tbody tr", count: 5
      assert_select "td", text: "5km"
      assert_select "td", text: "200"
      assert_select "td", text: "1"
    end
  end
end
