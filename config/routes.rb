Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[new create]

  resources :interview_sessions, only: %i[index new create show destroy] do
    resources :messages, only: :create, controller: "interview_messages"
    member do
      patch :abandon
      post  :feedback
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "interview_sessions#index"
end
