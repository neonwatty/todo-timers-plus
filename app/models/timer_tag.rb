class TimerTag < ApplicationRecord
  belongs_to :timer
  belongs_to :tag

  validates :timer_id, uniqueness: { scope: :tag_id }
end
