Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :connections,  only: [:create]
      resources :orgs, only: [:create] do
        member do
          get :graph
        end
      end
      resources :users, only: [:create, :show]

      get 'connection_preview', to: 'connections#preview'
    end
  end
end