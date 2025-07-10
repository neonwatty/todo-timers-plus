class CreateTimers < ActiveRecord::Migration[8.0]
  def change
    create_table :timers do |t|
      t.references :user, null: false, foreign_key: true
      t.string :task_name
      t.datetime :start_time
      t.datetime :end_time
      t.integer :duration
      t.text :tags
      t.string :status

      t.timestamps
    end
  end
end
