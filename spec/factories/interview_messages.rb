FactoryBot.define do
  factory :interview_message do
    interview_session { nil }
    role { 1 }
    content { "MyText" }
    input_tokens { 1 }
    output_tokens { 1 }
  end
end
