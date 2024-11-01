Rails.application.routes.draw do
  controller "static_pages" do
    root "home"

    get "about"
    get "faq", action: "frequently_asked_questions"
    get "privacy"
    get "terms"

    scope as: :blog, path: :blog do
      get "tips_for_starting_a_union"
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
