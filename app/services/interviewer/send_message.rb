# frozen_string_literal: true

module Interviewer
  class SendMessage
    MAX_BODY = 4_000

    def self.call(session:, body:)
      new(session, body).call
    end

    def initialize(session, body)
      @session = session
      @body = body.to_s.strip
    end

    def call
      return Result.failure(:blank)        if @body.empty?
      return Result.failure(:too_long)     if @body.length > MAX_BODY
      return Result.failure(:not_running) unless @session.status_running?

      message = @session.messages.create!(role: :user, content: @body)
      InterviewStreamJob.perform_later(@session.id)
      Result.success(:sent, message)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(:invalid, e.record.errors)
    end
  end
end
