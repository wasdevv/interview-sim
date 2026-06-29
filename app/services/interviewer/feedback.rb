# frozen_string_literal: true

module Interviewer
  module Feedback
    def self.generate(session)
      return Result.success(:already_generated, session) if session.feedback.present?
      return Result.failure(:not_finished) if session.status_running?

      text = backend.feedback(session)
      session.update!(feedback: text, feedback_generated_at: Time.current)
      Result.success(:generated, session)
    rescue => e
      Rails.logger.error("[Interviewer::Feedback] #{e.class}: #{e.message}")
      Result.failure(:error, [ "#{e.class.name}: #{e.message}" ])
    end

    def self.backend
      Interviewer::Claude.backend
    end
  end
end
