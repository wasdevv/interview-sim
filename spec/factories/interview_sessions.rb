FactoryBot.define do
  factory :interview_session do
    user { nil }
    role { "MyString" }
    level { "MyString" }
    status { 1 }
    system_prompt { "MyText" }
    completed_at { "2026-06-28 03:13:34" }
  end
end
