# frozen_string_literal: true

class AddIndexesToInterviewSessionsAndMessages < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :interview_sessions,
              %i[user_id created_at],
              order: { created_at: :desc },
              name: "idx_interview_sessions_user_created_at",
              algorithm: :concurrently

    add_index :interview_sessions,
              %i[user_id status],
              name: "idx_interview_sessions_user_status",
              algorithm: :concurrently

    add_index :interview_messages,
              %i[interview_session_id created_at],
              order: { created_at: :asc },
              name: "idx_interview_messages_session_created_at",
              algorithm: :concurrently
  end
end
