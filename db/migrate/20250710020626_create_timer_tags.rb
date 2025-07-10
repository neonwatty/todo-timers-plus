class CreateTimerTags < ActiveRecord::Migration[8.0]
  def change
    create_table :timer_tags do |t|
      t.references :timer, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
