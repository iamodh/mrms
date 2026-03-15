race = Race.find_or_create_by!(name: "서울마라톤 2026") do |r|
  r.event_date = DateTime.new(2026, 4, 12, 8, 0, 0)
  r.location = "서울 여의도공원"
  r.registration_deadline = DateTime.new(2026, 3, 31, 23, 59, 59)
end

[
  { name: "5km", capacity: 200, fee: 20_000, start_time: "09:00" },
  { name: "10km", capacity: 300, fee: 30_000, start_time: "08:30" },
  { name: "하프", capacity: 200, fee: 50_000, start_time: "08:00" },
  { name: "풀코스", capacity: 0, fee: 70_000, start_time: "07:30" }
].each do |attrs|
  Course.find_or_create_by!(race_id: race.id, name: attrs[:name]) do |c|
    c.capacity = attrs[:capacity]
    c.fee = attrs[:fee]
    c.start_time = Time.parse(attrs[:start_time])
  end
end

course_5k = Course.find_by!(race_id: race.id, name: "5km")

Registration.find_or_create_by!(race: race, name: "환불자", phone_number: "01099998888") do |r|
  r.course = course_5k
  r.birth_date = Date.new(1990, 5, 15)
  r.gender = "male"
  r.address = "서울시 강남구"
  r.status = "refunded"
  r.canceled_at = Time.current
end

if defined?(Faker)
  Faker::Config.locale = "ko"

  courses = Course.where(race_id: race.id).where("capacity > 0").to_a

  50.times do |i|
    course = courses.sample
    name = Faker::Name.name
    phone = "010#{rand(10_000_000..99_999_999)}"

    Registration.find_or_create_by!(race: race, name: name, phone_number: phone) do |r|
      r.course = course
      r.birth_date = Faker::Date.birthday(min_age: 18, max_age: 65)
      r.gender = %w[male female].sample
      r.address = "#{Faker::Address.city} #{Faker::Address.street_name}"
      if i % 10 == 9
        r.status = "canceled"
        r.canceled_at = Time.current
      end
    end
  end

  puts "Faker registrations: #{Registration.where(race_id: race.id).count} total"
end

puts "Seed complete: Race #{race.id}, #{Course.where(race_id: race.id).count} courses"
