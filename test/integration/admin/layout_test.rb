require "test_helper"

class Admin::LayoutTest < ActionDispatch::IntegrationTest
  test "admin pages display navigation bar with links" do
    admin_login

    get admin_root_path

    assert_select "nav" do
      assert_select "a[href=?]", admin_root_path, text: "대시보드"
      assert_select "a[href=?]", admin_registrations_path, text: "신청자 목록"
      assert_select "a[href=?]", admin_logout_path, text: "로그아웃"
    end
  end
end
