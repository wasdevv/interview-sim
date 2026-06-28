# frozen_string_literal: true

module Interviewer
  module Claude
    MissingApiKey = Adapters::Claude::MissingApiKey

    def self.stream(session:, &block)
      backend.stream(session: session, &block)
    end

    def self.backend
      case ENV.fetch("INTERVIEWER_BACKEND", default_backend)
      when "claude" then Adapters::Claude
      when "mock"   then Adapters::Mock
      else
        raise "INTERVIEWER_BACKEND inválido (use 'claude' ou 'mock')"
      end
    end

    def self.default_backend
      Rails.env.production? ? "claude" : "mock"
    end
  end
end
