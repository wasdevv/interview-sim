# frozen_string_literal: true

class InterviewStreamJob < ApplicationJob
  queue_as :default

  END_MARKER = "### Entrevista encerrada"

  discard_on ActiveJob::DeserializationError

  def perform(session_id, kickoff: false)
    session = InterviewSession.find(session_id)
    return unless session.status_running?

    placeholder = session.messages.create!(role: :assistant, content: "")
    target_id   = ActionView::RecordIdentifier.dom_id(placeholder, :content)
    accumulated = +""

    result = Interviewer::Claude.stream(session: session) do |delta|
      accumulated << delta
      broadcast_replace(session, target_id, accumulated)
    end

    if result.success?
      placeholder.update!(content: accumulated.presence || "(sem resposta)")
      if accumulated.start_with?(END_MARKER) || accumulated.include?("\n#{END_MARKER}")
        session.update!(status: :completed, completed_at: Time.current)
        broadcast_status(session)
      end
    else
      placeholder.update!(content: "[erro ao gerar resposta — tente novamente em alguns segundos]")
      broadcast_replace(session, target_id, placeholder.content)
    end
  end

  private

  def broadcast_replace(session, target_id, content)
    Turbo::StreamsChannel.broadcast_replace_to(
      [ session, :stream ],
      target: target_id,
      partial: "interview_messages/streaming",
      locals: { target_id: target_id, content: content }
    )
  end

  def broadcast_status(session)
    Turbo::StreamsChannel.broadcast_replace_to(
      [ session, :stream ],
      target: ActionView::RecordIdentifier.dom_id(session, :status),
      partial: "interview_sessions/status",
      locals: { session: session }
    )
  end
end
