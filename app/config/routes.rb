Rails.application.routes.draw do
  concern :upvotable do
    resources :upvotes, only: [:create]
  end

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :ballots, only: [:index, :create, :show] do
        resources :nominations, only: [:create]
        resources :terms, only: [:create]
        resources :votes, only: [:create]
      end
      resources :connections,  only: [:create]
      resources :flags, only: [:create]
      resources :flag_reports, only: [:index]
      resources :moderation_events, only: [:index, :create]
      resources :nominations, only: [:update]
      resources :offices, only: [:index]
      resources :orgs, only: [:create]
      resources :permissions, only: [] do
        collection do
          get ':scope', to: 'permissions#show_by_scope', as: 'show_by_scope'
          post ':scope', to: 'permissions#create_by_scope', as: 'create_by_scope'
        end
      end
      resources :posts, concerns: :upvotable, only: [:index, :create, :show] do
        resources :comments,
          concerns: :upvotable,
          only: [:index, :create],
          shallow: true do
            resources :comments, only: [:create]
          end
      end
      resources :users, only: [:index, :create, :show]

      get 'connection_preview', to: 'connections#preview'
      get 'my_permissions', to: 'permissions#index_my_permissions', as: 'index_my_permissions'
      get 'org', to: 'orgs#my_org', as: 'my_org'
      patch 'org', to: 'orgs#update_my_org', as: 'update_my_org'
    end
  end
end
