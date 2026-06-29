# frozen_string_literal: true

require "anthropic"

module Interviewer
  module Adapters
    class Claude
      MODEL = "claude-haiku-4-5"
      MAX_TOKENS = 1024
      FEEDBACK_MAX_TOKENS = 2048

      class MissingApiKey < StandardError; end

      def self.client
        key = ENV["ANTHROPIC_API_KEY"].to_s.strip
        raise MissingApiKey, "ANTHROPIC_API_KEY não está setado (veja .env.example)" if key.empty?

        @client ||= Anthropic::Client.new(api_key: key)
      end

      def self.stream(session:, &block)
        new(session).stream(&block)
      end

      def self.feedback(session)
        new(session).feedback
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
      rescue Anthropic::Errors::APIError => e
        Rails.logger.error("[Interviewer::Adapters::Claude] #{e.class}: #{e.message}")
        Result.failure(:api_error, [ "#{e.class.name.demodulize}: #{e.message}" ])
      end

      def feedback
        response = self.class.client.messages.create(
          model: MODEL,
          max_tokens: FEEDBACK_MAX_TOKENS,
          messages: [ { role: "user", content: build_feedback_prompt } ]
        )
        text_block = response.content.find { |b| b.type == :text }
        text_block&.text.to_s.presence || "[Resposta vazia da IA — tente gerar de novo.]"
      rescue Anthropic::Errors::APIError => e
        Rails.logger.error("[Interviewer::Adapters::Claude] feedback #{e.class}: #{e.message}")
        "[Erro ao gerar feedback: #{e.class.name.demodulize}: #{e.message}]"
      end

      private

      def build_feedback_prompt
        <<~PROMPT
          Você é um entrevistador técnico veterano (ex-Big Tech) avaliando esta entrevista pra o cargo de **#{@session.role}** no nível **#{@session.level}**.

          Analise o transcript abaixo e produza feedback estruturado em markdown:

          ## Por resposta
          Pra CADA resposta do candidato, dê:
          - Nota de 0 a 10
          - 1 frase de feedback objetivo
          - 1 sugestão concreta de melhoria

          ## Geral
          - 3 pontos fortes
          - 3 pontos fracos críticos
          - Nota geral 0-10 calibrada pro nível #{@session.level}
          - Veredito: "Passa", "Passa com ressalvas", "Recusa", ou "Voltar em N meses"

          Tom: honesto, direto, construtivo. Português pt-BR. Sem floreio.

          # Transcript

          #{format_transcript}
        PROMPT
      end

      def format_transcript
        @session.messages.chronological.map.with_index(1) do |m, i|
          who = m.role_user? ? "CANDIDATO" : "ENTREVISTADOR"
          "[#{i}] #{who}:\n#{m.content}\n"
        end.join("\n")
      end
    end
  end
end
