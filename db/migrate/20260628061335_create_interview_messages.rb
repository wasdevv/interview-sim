# frozen_string_literal: true

class CreateInterviewMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :interview_messages do |t|
      t.references :interview_session, null: false, foreign_key: { on_delete: :cascade }
      t.integer :role,    null: false
      t.text    :content, null: false
      t.integer :input_tokens
      t.integer :output_tokens
      t.timestamps
    end
  end
end
