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

puts "Seed complete: Race #{race.id}, #{Course.where(race_id: race.id).count} courses"
