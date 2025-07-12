class AddNotesToTimerTemplates < ActiveRecord::Migration[8.0]
  def change
    add_column :timer_templates, :notes, :text
  end
end
