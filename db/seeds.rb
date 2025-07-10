# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create test user
test_user = User.find_or_create_by(email_address: 'test@example.com') do |user|
  user.password = 'password123'
end

puts "Created test user: #{test_user.email_address}"

# Create some sample timers
timers_data = [
  { task_name: 'Morning standup meeting', status: 'stopped', duration: 900 },
  { task_name: 'Work on feature implementation', status: 'stopped', duration: 7200 },
  { task_name: 'Code review', status: 'stopped', duration: 1800 },
  { task_name: 'Writing documentation', status: 'paused', duration: 2400 },
  { task_name: 'Current task - debugging', status: 'running', start_time: 10.minutes.ago }
]

timers_data.each do |timer_data|
  timer = test_user.timers.create!(
    task_name: timer_data[:task_name],
    status: timer_data[:status],
    duration: timer_data[:duration],
    start_time: timer_data[:start_time] || 1.hour.ago,
    end_time: timer_data[:status] == 'stopped' ? Time.current : nil
  )
  puts "Created timer: #{timer.task_name} (#{timer.status})"
end

puts "\nTest credentials:"
puts "Email: test@example.com"
puts "Password: password123"
puts "\nYou can now start the server with 'rails server' and test the app!"