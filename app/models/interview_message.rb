# frozen_string_literal: true

class InterviewMessage < ApplicationRecord
  BODY_MAX = 8_000

  enum :role, { user: 0, assistant: 1 }, prefix: true

  belongs_to :session, class_name: "InterviewSession",
             foreign_key: :interview_session_id, inverse_of: :messages

  validates :role,    presence: true
  validates :content, presence: true, length: { maximum: BODY_MAX }

  scope :chronological, -> { order(created_at: :asc) }
end
