# frozen_string_literal: true

class InterviewMessagesController < ApplicationController
  def create
    session = Current.user.interview_sessions.find(params[:interview_session_id])
    result = Interviewer::SendMessage.call(session: session, body: params.dig(:message, :content))

    if result.success?
      redirect_to interview_session_path(session)
    else
      redirect_to interview_session_path(session), alert: t_failure(result.code)
    end
  end

  private

  def t_failure(code)
    case code
    when :blank       then "Escreva uma resposta antes de enviar."
    when :too_long    then "Sua resposta passou de 4000 caracteres."
    when :not_running then "Essa entrevista já foi encerrada."
    else                   "Não foi possível enviar a mensagem."
    end
  end
end
