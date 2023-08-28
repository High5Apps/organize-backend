Rails.application.routes.draw do
  concern :up_votable do
    resources :up_votes, only: [:create]
  end

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :connections,  only: [:create]
      resources :orgs, only: [:create]
      resources :posts, concerns: :up_votable, only: [:index, :create] do
        resources :comments, 
          concerns: :up_votable, 
          only: [:index, :create], 
          shallow: true
      end
      resources :users, only: [:create, :show]

      get 'connection_preview', to: 'connections#preview'
      get 'org', to: 'orgs#my_org', as: 'my_org'
    end
  end
end
