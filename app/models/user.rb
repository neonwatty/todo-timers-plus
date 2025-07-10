class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :timers, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def active_timers
    timers.active
  end

  def total_time_today
    timers.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day)
          .sum(&:calculate_duration)
  end
end
