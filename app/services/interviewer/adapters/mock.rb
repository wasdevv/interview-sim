# frozen_string_literal: true

module Interviewer
  module Adapters
    class Mock
      CHUNK_SIZE = 5
      CHUNK_DELAY = 0.04

      WARMUP = [
        "Bem-vindo! Pra começar bem, se apresenta em 2 minutos: nome, anos de experiência e uma vitória técnica recente que te deu orgulho — pode ser uma feature, um refactor, uma migration grande.",
        "Pra quebrar o gelo: me conta rapidinho sua trajetória e qual problema mais legal você resolveu nos últimos 6 meses.",
        "Antes da gente entrar em tópicos técnicos — se apresenta brevemente e cita um projeto recente que tenha te ensinado algo novo."
      ].freeze

      EXPLORATION = [
        "Você citou que trabalhou com algum sistema crítico — me conta de uma vez que algo quebrou em produção. Como vocês descobriram, debugaram e qual foi a correção?",
        "Quando você precisa escolher entre consistência forte e disponibilidade num sistema distribuído, como você raciocina? Pode usar um exemplo do seu trabalho.",
        "Me explica uma decisão de arquitetura que você defendeu mas o time inicialmente discordou. O que você fez pra alinhar?",
        "Como você aborda performance numa API que está respondendo lento? Quais ferramentas e métricas você usa primeiro?",
        "Conta uma situação onde você teve que dizer 'não' pra uma feature ou request. Como você comunicou e o que aconteceu?",
        "Se você tivesse que reescrever um sistema legado do zero, mas só pudesse trocar 20% do código, em que você focaria?",
        "Me explica como você pensa em testes — quando vale escrever teste de integração vs unitário vs sistema?",
        "Qual foi a última vez que você aprendeu uma tecnologia nova fora do trabalho? O que motivou e como você abordou?",
        "Se você visse um colega entregando código com problemas de qualidade consistentemente, como você abordaria?",
        "Conta de uma vez que você reduziu complexidade de um sistema — pode ser deletando código, simplificando arquitetura ou removendo dependência."
      ].freeze

      CLOSE = [
        "Pra fechar, o que você está procurando aprender ou desenvolver nos próximos 12 meses na sua carreira?",
        "Última pergunta minha: tem alguma coisa sobre o time, processo ou produto que você gostaria de saber?"
      ].freeze

      END_MESSAGE = "### Entrevista encerrada\n\nObrigado pela conversa — bons insights! Em uma entrevista real, eu compartilharia feedback estruturado neste momento. Boa sorte na próxima!"

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
        text = pick_text
        chunks_for(text).each do |chunk|
          sleep CHUNK_DELAY
          block.call(chunk)
        end
        Result.success(:streamed)
      end

      def feedback
        user_msgs = @session.messages.role_user.to_a
        return "Sem respostas suficientes pra análise." if user_msgs.empty?

        total = user_msgs.size
        avg_words = (user_msgs.sum { |m| m.content.split.size }.to_f / total).round
        short = user_msgs.count { |m| m.content.split.size < 30 }
        nothing = user_msgs.count { |m| m.content.match?(/\A(n[aã]o|nada|nenhum[ao]?|nunca)\.?\z/i) }

        <<~MD
          ## Feedback automático (backend mock)

          > Análise por template estático. Pra crítica personalizada por IA, troque `INTERVIEWER_BACKEND=claude` no `.env`.

          ### Métricas da sessão

          - Cargo: **#{@session.role}** (nível: #{@session.level})
          - Respostas dadas: **#{total}**
          - Média de palavras por resposta: **#{avg_words}**
          - Respostas curtas (<30 palavras): **#{short}** de #{total}
          - Respostas vazias ("nada", "não", "nenhuma"): **#{nothing}**

          ### Padrões observáveis

          #{padroes(short, total, nothing, avg_words)}

          ### Próximos passos sugeridos

          1. **Storytelling com STAR+R**: cada resposta com Situação → Tarefa → Ação → Resultado mensurável → Reflexão sobre o que aprendeu.
          2. **Fundamentos**: revisar sistemas distribuídos (CAP, ACID, eventual consistency), performance (profiling, EXPLAIN ANALYZE, APM) e práticas de teste.
          3. **Fim da entrevista**: sempre tenha 2-3 perguntas guardadas (cultura, processo de release, métricas de sucesso pro cargo).

          ### Como conseguir feedback real

          Edita `.env` pra `INTERVIEWER_BACKEND=claude` + `ANTHROPIC_API_KEY=sk-ant-...` e gera de novo. Aí cada resposta vai ser analisada individualmente com nota e sugestão concreta.
        MD
      end

      private

      def pick_text
        turn = @session.messages.role_user.count
        case turn
        when 0 then sample(WARMUP, seed_offset: 0)
        when 1..(EXPLORATION.size) then sample(EXPLORATION, seed_offset: turn)
        when (EXPLORATION.size + 1) then CLOSE[0]
        when (EXPLORATION.size + 2) then CLOSE[1]
        else END_MESSAGE
        end
      end

      def sample(pool, seed_offset:)
        index = (@session.id + seed_offset) % pool.size
        pool[index]
      end

      def chunks_for(text)
        text.chars.each_slice(CHUNK_SIZE).map(&:join)
      end

      def padroes(short, total, nothing, avg_words)
        notes = []
        notes << "- ⚠️ **#{short} de #{total} respostas curtas demais** — respostas com <30 palavras raramente comunicam contexto, ação e resultado." if short > total / 2
        notes << "- ⚠️ **#{nothing} resposta(s) sem conteúdo** (\"nada\", \"não houve\", etc) — entrevistador interpreta como falta de exemplo ou desinteresse." if nothing.positive?
        notes << "- 📏 **Média de #{avg_words} palavras por resposta** — pleno+ costuma usar 80-150 palavras pra resposta técnica completa." if avg_words < 50
        notes << "- ✅ Respostas com boa extensão na média — bom sinal de articulação." if avg_words >= 80 && short < total / 3
        notes.empty? ? "- Sem padrões claros — sessão equilibrada." : notes.join("\n")
      end
    end
  end
end
