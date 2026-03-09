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
end
