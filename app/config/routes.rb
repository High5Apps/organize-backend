Rails.application.routes.draw do
  concern :upvotable do
    resources :upvotes, only: [:create]
  end

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :ballots, only: [:index, :create, :show] do
        resources :candidates, only: [:index]
      end
      resources :connections,  only: [:create]
      resources :orgs, only: [:create]
      resources :posts, concerns: :upvotable, only: [:index, :create] do
        resources :comments,
          concerns: :upvotable,
          only: [:index, :create],
          shallow: true do
            resources :comments, only: [:create]
          end
      end
      resources :users, only: [:create, :show]

      get 'connection_preview', to: 'connections#preview'
      get 'org', to: 'orgs#my_org', as: 'my_org'
    end
  end
end
