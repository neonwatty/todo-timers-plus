# Additional seed data for testing analytics
# Run with: rails runner db/seeds_analytics.rb

user = User.find_by(email_address: 'test@example.com')

unless user
  puts "Test user not found. Please run 'rails db:seed' first."
  exit
end

puts "Adding analytics test data for #{user.email_address}..."

# Create timers for the past month with varied patterns
tasks = [
  'Email and communication',
  'Team meetings',
  'Code development',
  'Code review',
  'Documentation writing',
  'Bug fixing',
  'Project planning',
  'Learning and research',
  'Client calls',
  'Testing and QA'
]

# Generate data for the past 30 days
30.times do |days_ago|
  date = days_ago.days.ago
  
  # Skip weekends for more realistic data
  next if date.saturday? || date.sunday?
  
  # Morning tasks (9 AM - 12 PM)
  if [true, false].sample # 50% chance
    timer = user.timers.create!(
      task_name: ['Email and communication', 'Team meetings'].sample,
      status: 'stopped',
      duration: rand(900..3600), # 15-60 minutes
      start_time: date.change(hour: 9) + rand(0..180).minutes,
      end_time: date.change(hour: 12),
      created_at: date.change(hour: 9),
      updated_at: date.change(hour: 12)
    )
  end
  
  # Main work (10 AM - 4 PM)
  main_tasks = ['Code development', 'Bug fixing', 'Project planning'].sample(2)
  main_tasks.each do |task|
    timer = user.timers.create!(
      task_name: task,
      status: 'stopped',
      duration: rand(3600..10800), # 1-3 hours
      start_time: date.change(hour: 10) + rand(0..120).minutes,
      end_time: date.change(hour: 16),
      created_at: date.change(hour: 10),
      updated_at: date.change(hour: 16)
    )
  end
  
  # Afternoon tasks (2 PM - 5 PM)
  if rand < 0.7 # 70% chance
    timer = user.timers.create!(
      task_name: ['Code review', 'Documentation writing', 'Testing and QA'].sample,
      status: 'stopped',
      duration: rand(1800..5400), # 30-90 minutes
      start_time: date.change(hour: 14) + rand(0..60).minutes,
      end_time: date.change(hour: 17),
      created_at: date.change(hour: 14),
      updated_at: date.change(hour: 17)
    )
  end
  
  # Occasional late work (5 PM - 7 PM)
  if rand < 0.3 # 30% chance
    timer = user.timers.create!(
      task_name: ['Bug fixing', 'Client calls', 'Learning and research'].sample,
      status: 'stopped',
      duration: rand(1800..3600), # 30-60 minutes
      start_time: date.change(hour: 17) + rand(0..60).minutes,
      end_time: date.change(hour: 19),
      created_at: date.change(hour: 17),
      updated_at: date.change(hour: 19)
    )
  end
end

# Add some timers for today with various statuses
today = Date.current

# Morning completed tasks
timer = user.timers.create!(
  task_name: 'Morning standup',
  status: 'stopped',
  duration: 900, # 15 minutes
  start_time: today.change(hour: 9),
  end_time: today.change(hour: 9, min: 15),
  created_at: today.change(hour: 9),
  updated_at: today.change(hour: 9, min: 15)
)

timer = user.timers.create!(
  task_name: 'Email and communication',
  status: 'stopped',
  duration: 1800, # 30 minutes
  start_time: today.change(hour: 9, min: 30),
  end_time: today.change(hour: 10),
  created_at: today.change(hour: 9, min: 30),
  updated_at: today.change(hour: 10)
)

# Currently active timer
timer = user.timers.create!(
  task_name: 'Feature development - Analytics Dashboard',
  status: 'running',
  start_time: 2.hours.ago,
  created_at: 2.hours.ago,
  updated_at: Time.current
)

puts "Analytics test data created successfully!"
puts "Total timers: #{user.timers.count}"
puts "This week: #{user.timers.where(created_at: Date.current.beginning_of_week..Date.current.end_of_week).count} timers"
puts "This month: #{user.timers.where(created_at: Date.current.beginning_of_month..Date.current.end_of_month).count} timers"