Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  post '/login', to: 'auth#login'
  post '/reset_pin', to: 'auth#reset_pin'
  post '/register', to: 'registrations#create'
  get '/validate_code/:code', to: 'registrations#validate_code'
  get '/teams', to: 'registrations#teams'

  get '/me', to: 'users#me'
  get '/book_lists', to: 'book_lists#index'
  get '/book_lists/:book_list_id/quiz_questions', to: 'quiz_questions#index'
  post '/quiz/attempt/start', to: 'quiz#attempt_start'
  post '/quiz/attempt', to: 'quiz#attempt'
  post '/quiz/challenge', to: 'quiz#challenge'
  get '/quiz/me', to: 'quiz#me'
  get '/quiz/team_stats', to: 'quiz#team_stats'
  get '/quiz/challengeable_teammates', to: 'quiz_matches#challengeable_teammates'
  get '/quiz_matches/pending_invite', to: 'quiz_matches#pending_invite'

  resources :quiz_matches, only: [:create, :show] do
    member do
      post :join
      post :answer
      post :timeout
      post :decline
    end
  end

  resources :teammates, only: [:index, :create, :update, :destroy] do
    member do
      post :reset_pin
    end
  end
  resources :books, only: [:index, :create, :update, :destroy]
  resources :book_assignments, only: [:index, :create, :update, :destroy]
  get '/my_books', to: 'book_assignments#my_books'
  patch '/my_team', to: 'teams#update_my_team'

  namespace :admin_panel, path: 'admin' do
    post '/login', to: 'auth#login'
    get '/stats', to: 'dashboard#stats'
    post '/demo_teammate', to: 'dashboard#demo_teammate'
    resources :invite_codes
    resources :teams, only: [:index, :show, :create, :update, :destroy] do
      resources :users, only: [:create, :update, :destroy], controller: 'team_users', param: :id
    end
    resources :book_lists do
      resources :book_list_items, path: 'books', only: [:create, :update, :destroy]
      resources :quiz_questions, path: 'questions', only: [:index, :create, :update, :destroy]
    end
  end

  mount ActionCable.server => '/cable'

  get '/health', to: ->(_) { [200, {}, ['OK']] }
end
