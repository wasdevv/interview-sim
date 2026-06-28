# frozen_string_literal: true

if Rails.env.development?
  user = User.find_or_initialize_by(email_address: "demo@interviewsim.test")
  user.assign_attributes(
    name:                  "Demo Candidato",
    password:              "DemoUser!2026Sim",
    password_confirmation: "DemoUser!2026Sim"
  )
  user.save!
  puts "Seeded demo@interviewsim.test / DemoUser!2026Sim"
end
