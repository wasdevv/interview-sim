# CLAUDE.md

## Visão geral

**InterviewSim** — simulador de entrevistas com IA via Claude API. Projeto de portfólio focado em prompt engineering, streaming server-side e UI conversacional.

## Stack

- **Ruby 4.0.5** via rbenv
- **Rails 8.1.3** + PostgreSQL local (`host=localhost user=postgres password=postgres`)
- **Tailwind CSS v4** + Importmap + Hotwire (Turbo + Stimulus)
- **Solid Cache/Queue/Cable** (sem Redis)
- **Anthropic SDK 1.50** (gem `anthropic`)
- **RSpec stack** já instalado mas ainda sem `bin/rails g rspec:install`

## M1 — escopo travado

Chat-first: 1 sessão de entrevista AI.

1. User signa/loga → home com botão "Nova entrevista"
2. Escolhe `role` (string livre, ex. "Backend Engineer") + `level` (`junior/pleno/senior/staff/principal`)
3. `InterviewSession` criada com `system_prompt` resolvido (cacheado por 5min via prompt caching)
4. AI inicia com a primeira pergunta (streaming via Turbo Stream chunked)
5. User responde, AI faz follow-up; ciclo até user clicar "Encerrar"
6. Transcript fica disponível em `/interview_sessions/:id` (read-only após encerrar)

Fora do escopo M1: feedback STAR+R, story bank, cover letter, PDF, multi-tenant.

## Comandos comuns

```bash
export PATH="$HOME/.rbenv/bin:$PATH" && eval "$(rbenv init - bash)"
bin/rails server          # web only
bin/dev                   # web + tailwind watcher via foreman
bin/rails console
bin/rails db:migrate db:seed
bin/jobs                  # Solid Queue worker
ANTHROPIC_API_KEY=sk-... bin/rails server   # streaming precisa do env var
```

## Convenções herdadas do PipelineHQ

- **Code em inglês, UI em pt-BR, zero comentários no código** (memória de usuário).
- **Branch + PR sempre** — nunca direto na main.
- **Result objects** em `app/services/result.rb` (vou trazer).
- **Migrations de índice separadas** com `algorithm: :concurrently`.
- **30 Golden Rules** do PipelineHQ aplicam por padrão.

## Estrutura

```
app/
├── services/
│   ├── interviewer/
│   │   ├── claude.rb              # wrapper do SDK + streaming
│   │   ├── prompt_template.rb     # resolve system prompt por (role, level)
│   │   └── start_session.rb       # service de criar session com Result
│   └── result.rb
├── jobs/
│   └── interview_stream_job.rb    # consome stream + broadcast Turbo
├── models/
│   ├── user.rb
│   ├── interview_session.rb
│   └── interview_message.rb
├── controllers/
│   ├── interview_sessions_controller.rb
│   └── interview_messages_controller.rb
└── views/...
```

## API key

Pra dev: `export ANTHROPIC_API_KEY=sk-ant-...` no shell antes de subir o server.
Pra prod: `Rails.application.credentials.anthropic_api_key` (a configurar quando deploy).

## Lições aprendidas

(Atualizar ao fim de cada feature.)
