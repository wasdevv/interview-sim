# frozen_string_literal: true

require "anthropic"

module Interviewer
  class Claude
    MODEL = "claude-haiku-4-5"
    MAX_TOKENS = 1024

    class MissingApiKey < StandardError; end

    def self.client
      key = ENV["ANTHROPIC_API_KEY"].to_s.strip
      raise MissingApiKey, "ANTHROPIC_API_KEY não está setado (veja .env.example)" if key.empty?

      @client ||= Anthropic::Client.new(api_key: key)
    end

    def self.stream(session:, &block)
      new(session).stream(&block)
    end

    def initialize(session)
      @session = session
    end

    def stream(&block)
      stream = self.class.client.messages.stream(
        model: MODEL,
        max_tokens: MAX_TOKENS,
        system_: [
          { type: "text", text: @session.system_prompt, cache_control: { type: "ephemeral" } }
        ],
        messages: @session.transcript
      )

      stream.text.each(&block)

      final = stream.respond_to?(:get_final_message) ? stream.get_final_message : nil
      Result.success(:streamed, final)
    rescue Anthropic::APIStatusError => e
      Result.failure(:api_error, [ e.message ])
    end
  end
end
