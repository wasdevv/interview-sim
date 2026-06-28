# frozen_string_literal: true

class InterviewSession < ApplicationRecord
  LEVELS = %w[junior pleno senior staff principal].freeze

  enum :status, { running: 0, completed: 1, abandoned: 2 }, default: :running, prefix: true

  belongs_to :user, inverse_of: :interview_sessions
  has_many :messages, class_name: "InterviewMessage",
           dependent: :destroy, inverse_of: :session, foreign_key: :interview_session_id

  validates :role,          presence: true, length: { in: 2..80 }
  validates :level,         presence: true, inclusion: { in: LEVELS }
  validates :system_prompt, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def transcript
    messages.order(:created_at).map { |m| { role: m.role, content: m.content } }
  end
end
