# frozen_string_literal: true

class CreateInterviewSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :interview_sessions do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string  :role,           null: false, limit: 80
      t.string  :level,          null: false, limit: 40
      t.integer :status,         null: false, default: 0
      t.text    :system_prompt,  null: false
      t.datetime :completed_at
      t.timestamps
    end
  end
end
