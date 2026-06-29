# frozen_string_literal: true

class GenerateFeedbackJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError

  def perform(session_id)
    session = InterviewSession.find(session_id)
    return if session.status_running?
    return if session.feedback.present?

    Interviewer::Feedback.generate(session)
    broadcast_feedback(session.reload)
  end

  private

  def broadcast_feedback(session)
    Turbo::StreamsChannel.broadcast_replace_to(
      [ session, :stream ],
      target: ActionView::RecordIdentifier.dom_id(session, :feedback),
      partial: "interview_sessions/feedback",
      locals: { session: session }
    )
  end
end
