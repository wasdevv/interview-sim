class AddFeedbackToInterviewSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :interview_sessions, :feedback, :text
    add_column :interview_sessions, :feedback_generated_at, :datetime
  end
end
