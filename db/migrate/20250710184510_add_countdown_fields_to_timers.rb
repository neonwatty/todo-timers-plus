class AddCountdownFieldsToTimers < ActiveRecord::Migration[8.0]
  def change
    # Target duration in seconds - the original countdown time set by user
    add_column :timers, :target_duration, :integer
    
    # Remaining duration in seconds - used when timer is paused
    add_column :timers, :remaining_duration, :integer
    
    # Timestamp when countdown reached zero
    add_column :timers, :completed_at, :datetime
    
    # Add indexes for completed timers queries
    add_index :timers, :completed_at
  end
end
