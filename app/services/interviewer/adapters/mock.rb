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

      CONCEPTUAL = [
        "Vamos pra um conceito básico: o que é uma transação em banco de dados e quando você usa?",
        "Me explica em poucas palavras o que diferencia HTTP de HTTPS além do 'S' de seguro.",
        "O que é um índice em SQL? Em que situações um índice pode até atrapalhar a performance?",
        "Me explica o que é idempotência em APIs. Por que isso importa especialmente em endpoints de pagamento?",
        "Conta o que significa ACID. Pode dar 1 exemplo prático de cada letra.",
        "Qual a diferença prática entre cache HTTP (Cache-Control) e cache de aplicação (Redis/Memcached)?",
        "Me explica a diferença entre GET, POST, PUT e PATCH numa API REST — quando escolher cada um.",
        "O que é um deadlock em código concorrente? Como você detecta e como evita?",
        "Explica o N+1 query problem com um exemplo. Como você identifica e resolve no seu stack atual?",
        "O que é dependency injection? Quando vale a pena e quando complica mais do que ajuda?",
        "Diferença prática entre processo e thread. Quando você escolheria um ou outro?",
        "Me explica eventual consistency. Em que tipos de sistema ela é aceitável e em quais não é?",
        "Qual a diferença entre autenticação e autorização? Cita 1 ferramenta/protocolo pra cada.",
        "O que é uma race condition? Conta um exemplo (real ou hipotético) e como evitar."
      ].freeze

      PRACTICAL = [
        "Agora algo mais prático: como você implementaria paginação numa API que retorna 10M de registros?",
        "Você precisa fazer retry de uma chamada externa que pode falhar intermitentemente. Como você desenha isso sem causar tempestade de requests?",
        "Como você projetaria um sistema de notificações por email garantindo at-least-once delivery?",
        "Imagina um endpoint que vai ser chamado 10k vezes por segundo. Como você protege a infra de cair?",
        "Como você faria pra adicionar uma coluna NOT NULL numa tabela com 100M de rows em produção, zero downtime?",
        "Como você invalidaria cache distribuído quando o dado fonte muda? Quais armadilhas?",
        "Você precisa fazer full-text search em 1M de documentos. Quais opções considera, quais os trade-offs?",
        "Como você desenharia um sistema de feature flags pra fazer rollout gradual sem deploy?",
        "Pra deletar 50M de rows antigas em prod, qual sua abordagem? Quais cuidados?",
        "Como você detectaria que uma versão nova do seu serviço está com regressão de performance logo após o deploy?"
      ].freeze

      SCENARIO = [
        "Conta de uma vez que algo quebrou em produção. Como vocês descobriram, debugaram e qual foi a correção?",
        "Me explica uma decisão de arquitetura que você defendeu mas o time inicialmente discordou. O que você fez pra alinhar?",
        "Conta uma situação onde você teve que dizer 'não' pra uma feature ou request. Como você comunicou e o que aconteceu?",
        "Se você tivesse que reescrever um sistema legado do zero, mas só pudesse trocar 20% do código, em que você focaria?",
        "Qual foi a última vez que você aprendeu uma tecnologia nova fora do trabalho? O que motivou e como você abordou?",
        "Se você visse um colega entregando código com problemas de qualidade consistentemente, como você abordaria?",
        "Conta de uma vez que você reduziu complexidade de um sistema — pode ser deletando código, simplificando arquitetura ou removendo dependência.",
        "Me conta um conflito técnico que você teve com outro engenheiro. Como vocês chegaram numa solução?",
        "Se você tivesse que liderar um projeto novo do zero amanhã, quais 3 decisões técnicas você travaria primeiro?",
        "Conta de um trade-off complicado que você teve que fazer recentemente. Como você decidiu?"
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

      PHASES = [
        [ :warmup,      WARMUP,      1 ],
        [ :conceptual,  CONCEPTUAL,  3 ],
        [ :practical,   PRACTICAL,   3 ],
        [ :scenario,    SCENARIO,    3 ],
        [ :close_first, CLOSE,       1 ],
        [ :close_last,  CLOSE,       1 ]
      ].freeze

      def pick_text
        turn = @session.messages.role_user.count

        cumulative = 0
        PHASES.each_with_index do |(phase, pool, count), phase_idx|
          if turn < cumulative + count
            offset = turn - cumulative
            return CLOSE[0] if phase == :close_first
            return CLOSE[1] if phase == :close_last

            return sample(pool, seed_offset: phase_idx * 7 + offset)
          end
          cumulative += count
        end

        END_MESSAGE
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
