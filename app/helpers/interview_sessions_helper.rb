# frozen_string_literal: true

module InterviewSessionsHelper
  def status_label(session)
    case session.status
    when "running"   then "Em andamento"
    when "completed" then "Encerrada"
    when "abandoned" then "Abandonada"
    end
  end

  def status_badge_class(session)
    case session.status
    when "running"   then "bg-emerald-100 text-emerald-700"
    when "completed" then "bg-indigo-100 text-indigo-700"
    when "abandoned" then "bg-zinc-200 text-zinc-600"
    end
  end
end
