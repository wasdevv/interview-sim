# frozen_string_literal: true

class InterviewSessionsController < ApplicationController
  before_action :set_session, only: %i[show abandon destroy]

  def index
    @sessions = Current.user.interview_sessions.recent.limit(20)
  end

  def new
    @levels = InterviewSession::LEVELS
  end

  def create
    result = Interviewer::StartSession.call(
      user:  Current.user,
      role:  params[:role],
      level: params[:level]
    )

    if result.success?
      redirect_to interview_session_path(result.payload)
    else
      redirect_to new_interview_session_path, alert: t_failure(result.code)
    end
  end

  def show
    @messages = @session.messages.chronological
  end

  def abandon
    @session.update!(status: :abandoned, completed_at: Time.current)
    redirect_to interview_sessions_path, notice: "Entrevista encerrada."
  end

  def destroy
    @session.destroy!
    redirect_to interview_sessions_path, notice: "Entrevista apagada.", status: :see_other
  end

  private

  def set_session
    @session = Current.user.interview_sessions.find(params[:id])
  end

  def t_failure(code)
    case code
    when :invalid_role  then "Cargo precisa ter no mínimo 2 caracteres."
    when :invalid_level then "Nível inválido."
    else                     "Não foi possível iniciar a entrevista."
    end
  end
end
