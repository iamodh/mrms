require "test_helper"

class LookupTest < ActionDispatch::IntegrationTest
  test "lookup with valid confirmation_code and name shows registration details" do
    registration = registrations(:hong_5km)

    post lookup_path, params: {
      confirmation_code: registration.confirmation_code,
      name: registration.name
    }

    assert_response :success
    assert_select "dd", text: /#{registration.confirmation_code}/
  end

  test "lookup with invalid information shows error message" do
    post lookup_path, params: {
      confirmation_code: "ZZZZZZZZ",
      name: "없는사람"
    }

    assert_redirected_to lookup_path
    assert_equal "신청 내역을 찾을 수 없습니다.", flash[:alert]
  end

  test "cancel changes status to canceled and records canceled_at" do
    registration = registrations(:hong_5km)

    delete lookup_path, params: {
      confirmation_code: registration.confirmation_code,
      name: registration.name
    }

    registration.reload
    assert registration.canceled?
    assert_not_nil registration.canceled_at
    assert_redirected_to lookup_path
    assert_equal "신청이 취소되었습니다.", flash[:notice]
  end

  test "canceling already canceled registration succeeds without error" do
    registration = registrations(:hong_5km)
    registration.cancel!

    delete lookup_path, params: {
      confirmation_code: registration.confirmation_code,
      name: registration.name
    }

    assert_redirected_to lookup_path
    assert_equal "신청이 취소되었습니다.", flash[:notice]
  end

  test "canceling after registration deadline is blocked" do
    registration = registrations(:closed_registration)

    delete lookup_path, params: {
      confirmation_code: registration.confirmation_code,
      name: registration.name
    }

    assert_redirected_to lookup_path
    assert_equal "취소 가능 기간이 지났습니다.", flash[:alert]
  end
end
