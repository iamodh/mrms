require "test_helper"

class RegistrationTest < ActiveSupport::TestCase
  test "belongs to race" do
    registration = registrations(:hong_5km)
    assert_equal races(:marathon_2026), registration.race
  end

  test "belongs to course" do
    registration = registrations(:hong_5km)
    assert_equal courses(:five_km), registration.course
  end

  test "normalizes name by removing spaces" do
    registration = registrations(:hong_5km)
    registration.name = "홍 길 동"
    assert_equal "홍길동", registration.name
  end

  test "normalizes phone_number by removing non-digits" do
    registration = registrations(:hong_5km)
    registration.phone_number = "010-1234-5678"
    assert_equal "01012345678", registration.phone_number
  end

  test "rejects name longer than 10 characters" do
    registration = registrations(:hong_5km)
    registration.name = "가" * 11
    assert_not registration.valid?
    assert_includes registration.errors[:name], "is too long (maximum is 10 characters)"
  end

  test "rejects phone_number that is not exactly 11 digits" do
    registration = registrations(:hong_5km)

    registration.phone_number = "0" * 9
    assert_not registration.valid?
    assert_includes registration.errors[:phone_number], "is the wrong length (should be 11 characters)"

    registration.phone_number = "0" * 12
    assert_not registration.valid?
    assert_includes registration.errors[:phone_number], "is the wrong length (should be 11 characters)"
  end

  test "rejects address longer than 30 characters" do
    registration = registrations(:hong_5km)
    registration.address = "가" * 31
    assert_not registration.valid?
    assert_includes registration.errors[:address], "is too long (maximum is 30 characters)"
  end

  test "rejects duplicate registration with same race, name, and phone_number even on different course" do
    existing = registrations(:hong_5km)
    duplicate = Registration.new(
      race: existing.race,
      course: courses(:ten_km),
      name: existing.name,
      phone_number: existing.phone_number,
      birth_date: "1995-06-15",
      gender: "female",
      address: "부산시 해운대구"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "이미 동일한 이름과 전화번호로 신청된 내역이 있습니다."
  end

  test "generates confirmation_code of 8 uppercase alphanumeric characters on create" do
    registration = Registration.create!(
      course: courses(:five_km),
      name: "테스트",
      phone_number: "01099998888",
      birth_date: "2000-01-01",
      gender: "male",
      address: "서울시 강남구"
    )
    assert_match(/\A[A-Z0-9]{8}\z/, registration.confirmation_code)
  end

  test "cancelable? returns true when applied and registration open" do
    assert registrations(:hong_5km).cancelable?
  end

  test "cancelable? returns false when registration closed" do
    assert_not registrations(:closed_registration).cancelable?
  end

  test "cancelable? returns false when canceled or refunded" do
    registration = registrations(:hong_5km)

    registration.status = :canceled
    assert_not registration.cancelable?

    registration.status = :refunded
    assert_not registration.cancelable?
  end

  test "cancel! changes status to canceled and sets canceled_at" do
    registration = registrations(:hong_5km)
    registration.cancel!
    assert registration.canceled?
    assert_not_nil registration.canceled_at
  end

  test "cancel! is idempotent for already canceled registration" do
    registration = registrations(:hong_5km)
    registration.cancel!
    assert registration.cancel!
  end

  test "cancel! raises NotCancelableError when registration closed" do
    registration = registrations(:closed_registration)
    assert_raises(Registration::NotCancelableError) { registration.cancel! }
  end

  test "requires name, phone_number, birth_date, gender, and address" do
    registration = registrations(:hong_5km)
    registration.name = nil
    registration.phone_number = nil
    registration.birth_date = nil
    registration.gender = nil
    registration.address = nil
    assert_not registration.valid?
    assert_includes registration.errors[:name], "can't be blank"
    assert_includes registration.errors[:phone_number], "can't be blank"
    assert_includes registration.errors[:birth_date], "can't be blank"
    assert_includes registration.errors[:gender], "can't be blank"
    assert_includes registration.errors[:address], "can't be blank"
  end
end
