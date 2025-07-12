class CreateTimerTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :timer_templates do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :task_name
      t.string :timer_type, default: 'stopwatch', null: false
      t.integer :target_duration
      t.text :tags
      t.integer :usage_count, default: 0, null: false
      t.datetime :last_used_at

      t.timestamps
    end
    
    add_index :timer_templates, [:user_id, :name], unique: true
    add_index :timer_templates, :usage_count
    add_index :timer_templates, :last_used_at
  end
end
