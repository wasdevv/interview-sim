# frozen_string_literal: true

module Interviewer
  class StartSession
    def self.call(user:, role:, level:)
      new(user, role, level).call
    end

    def initialize(user, role, level)
      @user = user
      @role = role.to_s.strip
      @level = level.to_s
    end

    def call
      return Result.failure(:invalid_role)  if @role.length < 2
      return Result.failure(:invalid_level) unless InterviewSession::LEVELS.include?(@level)

      prompt = PromptTemplate.call(role: @role, level: @level)
      session = @user.interview_sessions.create!(
        role: @role,
        level: @level,
        system_prompt: prompt
      )
      InterviewStreamJob.perform_later(session.id, kickoff: true)
      Result.success(:started, session)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(:invalid, e.record.errors)
    end
  end
end
