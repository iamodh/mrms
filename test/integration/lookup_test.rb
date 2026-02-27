require "test_helper"

class LookupTest < ActionDispatch::IntegrationTest
  test "lookup with valid confirmation_code and name shows registration details" do
    registration = registrations(:hong_5km)

    post lookup_path, params: {
      confirmation_code: registration.confirmation_code,
      name: registration.name
    }

    assert_response :success
    assert_select ".confirmation-code", text: /#{registration.confirmation_code}/
  end

  test "lookup with invalid information shows error message" do
    post lookup_path, params: {
      confirmation_code: "ZZZZZZZZ",
      name: "없는사람"
    }

    assert_redirected_to lookup_path
    assert_equal "신청 내역을 찾을 수 없습니다.", flash[:alert]
  end
end
