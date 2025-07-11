class AddTimerTypeToTimers < ActiveRecord::Migration[8.0]
  def change
    add_column :timers, :timer_type, :string, default: "stopwatch", null: false
    add_index :timers, :timer_type
  end
end
