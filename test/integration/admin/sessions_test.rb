require "test_helper"

class Admin::SessionsTest < ActionDispatch::IntegrationTest
  test "login with valid credentials creates session" do
    post admin_login_path, params: { id: ENV["ADMIN_ID"], password: ENV["ADMIN_PW"] }

    assert_redirected_to admin_root_path
    assert session[:admin]
  end

  test "login with invalid credentials fails" do
    post admin_login_path, params: { id: "wrong", password: "wrong" }

    assert_response :unprocessable_entity
    assert_nil session[:admin]
    assert_select "div", text: /아이디 또는 비밀번호가 올바르지 않습니다/
  end

  test "logout destroys session" do
    admin_login

    delete admin_logout_path

    assert_redirected_to admin_login_path
    assert_nil session[:admin]
  end
end
