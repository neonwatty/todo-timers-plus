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
  # Stopwatch timers (count up)
  { task_name: 'Morning standup meeting', status: 'stopped', duration: 900 },
  { task_name: 'Work on feature implementation', status: 'stopped', duration: 7200 },
  { task_name: 'Code review', status: 'stopped', duration: 1800 },
  
  # Countdown timers
  { 
    task_name: 'Pomodoro Work Session', 
    status: 'stopped', 
    target_duration: 1500, # 25 minutes
    remaining_duration: 1500
  },
  { 
    task_name: 'Short Break', 
    status: 'stopped', 
    target_duration: 300, # 5 minutes
    remaining_duration: 300
  },
  { 
    task_name: 'Test Countdown (Running)', 
    status: 'running', 
    target_duration: 600, # 10 minutes
    remaining_duration: 600,
    start_time: Time.current
  },
  { 
    task_name: 'Lunch Break', 
    status: 'paused', 
    target_duration: 3600, # 60 minutes
    remaining_duration: 2400, # 40 minutes left
    duration: 1200 # 20 minutes elapsed
  }
]

timers_data.each do |timer_data|
  timer = test_user.timers.find_or_create_by!(task_name: timer_data[:task_name]) do |t|
    t.status = timer_data[:status]
    t.duration = timer_data[:duration]
    t.target_duration = timer_data[:target_duration]
    t.remaining_duration = timer_data[:remaining_duration]
    t.start_time = timer_data[:start_time] || (timer_data[:status] != 'stopped' ? 1.hour.ago : nil)
    t.end_time = timer_data[:status] == 'stopped' ? Time.current : nil
  end
  timer_type = timer.countdown? ? 'countdown' : 'stopwatch'
  puts "Created #{timer_type} timer: #{timer.task_name} (#{timer.status})"
end

puts "\nTest credentials:"
puts "Email: test@example.com"
puts "Password: password123"
puts "\nYou can now start the server with 'rails server' and test the app!"