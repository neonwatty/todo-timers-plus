# Analytics Demo Seed Data
# Run with: rails db:seed:load_file db/seeds_analytics_demo.rb

puts "Creating analytics demo data..."

# Find or create demo user
demo_user = User.find_or_create_by(email_address: "analytics@demo.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
end

puts "Demo user: #{demo_user.email_address}"

# Clear existing timers for clean demo
demo_user.timers.destroy_all

# Helper to create completed timers with specific times
def create_timer(user, task_name, start_time, duration_minutes, tags = [])
  timer = user.timers.build(
    task_name: task_name,
    start_time: start_time,
    end_time: start_time + duration_minutes.minutes,
    duration: duration_minutes * 60,
    status: "completed",
    created_at: start_time,
    updated_at: start_time + duration_minutes.minutes
  )
  timer[:tags] = tags.join(", ")
  timer.save!
  puts "  Created: #{task_name} - #{duration_minutes} minutes"
  timer
end

# Create timers for the past month with varied patterns
puts "\nCreating timers for analytics visualization..."

# Week 1 - Light week (4 weeks ago)
base_date = 4.weeks.ago.beginning_of_week
create_timer(demo_user, "Project Planning", base_date + 9.hours, 45, ["work", "planning"])
create_timer(demo_user, "Email Management", base_date + 10.hours, 30, ["work", "admin"])
create_timer(demo_user, "Team Meeting", base_date + 1.day + 14.hours, 60, ["work", "meetings"])
create_timer(demo_user, "Code Review", base_date + 2.days + 11.hours, 90, ["work", "development"])
create_timer(demo_user, "Learning Ruby", base_date + 3.days + 19.hours, 45, ["personal", "learning"])

# Week 2 - Productive week (3 weeks ago)
base_date = 3.weeks.ago.beginning_of_week
create_timer(demo_user, "Feature Development", base_date + 8.hours, 180, ["work", "development"])
create_timer(demo_user, "Bug Fixing", base_date + 14.hours, 120, ["work", "development"])
create_timer(demo_user, "Documentation", base_date + 1.day + 9.hours, 90, ["work", "docs"])
create_timer(demo_user, "Client Call", base_date + 1.day + 11.hours, 45, ["work", "meetings"])
create_timer(demo_user, "Code Review", base_date + 2.days + 10.hours, 60, ["work", "development"])
create_timer(demo_user, "Sprint Planning", base_date + 2.days + 14.hours, 90, ["work", "planning"])
create_timer(demo_user, "Testing", base_date + 3.days + 9.hours, 150, ["work", "development"])
create_timer(demo_user, "Exercise", base_date + 3.days + 18.hours, 45, ["personal", "health"])
create_timer(demo_user, "Side Project", base_date + 4.days + 20.hours, 120, ["personal", "development"])

# Week 3 - Mixed week (2 weeks ago)
base_date = 2.weeks.ago.beginning_of_week
create_timer(demo_user, "API Development", base_date + 9.hours, 240, ["work", "development"])
create_timer(demo_user, "Database Optimization", base_date + 1.day + 10.hours, 180, ["work", "development"])
create_timer(demo_user, "Team Standup", base_date + 1.day + 9.hours, 15, ["work", "meetings"])
create_timer(demo_user, "Performance Testing", base_date + 2.days + 14.hours, 120, ["work", "testing"])
create_timer(demo_user, "Learning Rails", base_date + 2.days + 19.hours, 90, ["personal", "learning"])
create_timer(demo_user, "Writing Blog Post", base_date + 3.days + 10.hours, 75, ["personal", "writing"])
create_timer(demo_user, "Meditation", base_date + 4.days + 7.hours, 20, ["personal", "health"])

# This week - Current activity
base_date = Date.current.beginning_of_week

# Monday
create_timer(demo_user, "Sprint Planning", base_date + 9.hours, 60, ["work", "planning"])
create_timer(demo_user, "Feature Development", base_date + 10.hours + 15.minutes, 165, ["work", "development"])
create_timer(demo_user, "Lunch Break", base_date + 13.hours, 45, ["personal", "break"])
create_timer(demo_user, "Code Review", base_date + 14.hours, 90, ["work", "development"])
create_timer(demo_user, "Email Management", base_date + 16.hours, 30, ["work", "admin"])

# Tuesday
if Date.current > base_date + 1.day
  create_timer(demo_user, "Bug Fixing", base_date + 1.day + 8.hours + 30.minutes, 150, ["work", "development"])
  create_timer(demo_user, "Team Meeting", base_date + 1.day + 11.hours + 30.minutes, 60, ["work", "meetings"])
  create_timer(demo_user, "Documentation", base_date + 1.day + 14.hours, 120, ["work", "docs"])
  create_timer(demo_user, "Learning Kubernetes", base_date + 1.day + 19.hours, 60, ["personal", "learning"])
end

# Wednesday (if we're past it)
if Date.current > base_date + 2.days
  create_timer(demo_user, "API Development", base_date + 2.days + 9.hours, 180, ["work", "development"])
  create_timer(demo_user, "Testing", base_date + 2.days + 14.hours, 120, ["work", "testing"])
  create_timer(demo_user, "Exercise", base_date + 2.days + 18.hours, 45, ["personal", "health"])
end

# Today's timers (for daily view)
if Time.current.hour >= 9
  create_timer(demo_user, "Morning Standup", Date.current + 9.hours, 15, ["work", "meetings"])
end
if Time.current.hour >= 10
  create_timer(demo_user, "Feature Development", Date.current + 9.hours + 30.minutes, 120, ["work", "development"])
end
if Time.current.hour >= 14
  create_timer(demo_user, "Afternoon Code Review", Date.current + 14.hours, 60, ["work", "development"])
end

# Create one running timer
if Time.current.hour >= 8 && Time.current.hour < 18
  running_timer = demo_user.timers.build(
    task_name: "Working on Analytics Feature",
    start_time: 30.minutes.ago,
    status: "running"
  )
  running_timer[:tags] = "work, development, analytics"
  running_timer.save!
  puts "  Created running timer: #{running_timer.task_name}"
end

# Summary
puts "\n✅ Analytics demo data created!"
puts "Total timers: #{demo_user.timers.count}"
puts "This week: #{demo_user.timers.where(created_at: Date.current.beginning_of_week..).count}"
puts "Today: #{demo_user.timers.where(created_at: Date.current.beginning_of_day..).count}"
puts "\n📊 Login with analytics@demo.com / password123 to see the analytics dashboard!"