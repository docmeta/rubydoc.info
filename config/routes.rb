Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "healthcheck" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  root "github#index"

  get "/about", to: "about#index", as: :about
  get "/help", to: "help#index", as: :help
  get "/docs", to: redirect("/featured", status: 302)

  resources :stdlib, only: [ :index ]

  if Rubydoc.config.github_hosting.enabled
    post "/checkout", to: "github_webhook#create"
    post "/checkout/github", to: "github_webhook#create"
    post "/projects/update", to: "github_webhook#update"
    get "/github/+", to: "github#add_project", as: :add_github_project
    post "/github/+", to: "github#create", as: :create_github_project

    resources :github, only: [ :index ] do
      get "~:letter(/:page)", on: :collection, action: :index, as: :letter
    end
  end

  if Rubydoc.config.gem_hosting.enabled
    post "/checkout/rubygems", to: "rubygems_webhook#create"
    resources :featured, only: [ :index ]
    resources :gems, only: [ :index ] do
      get "~:letter(/:page)", on: :collection, action: :index, as: :letter
    end
  end

  %W[#{} search/ list/].each do |prefix|
    get "#{prefix}docs/:name(/*rest)", to: "yard#featured", as: prefix.blank? ? "yard_featured" : nil
    get "#{prefix}stdlib/:name(/*rest)", to: "yard#stdlib", as: prefix.blank? ? "yard_stdlib" : nil
    get "#{prefix}gems/:name(/*rest)", to: "yard#gems", as: prefix.blank? ? "yard_gems" : nil
    get "#{prefix}github/:username/:project(/*rest)", to: "yard#github", as: prefix.blank? ? "yard_github" : nil
  end

  get "/static/docs/:name/*rest(.:format)", to: redirect("/assets/%{rest}.%{format}", status: 302)
  get "/static/stdlib/:name/*rest(.:format)", to: redirect("/assets/%{rest}.%{format}", status: 302)
  get "/static/gems/:name/*rest(.:format)", to: redirect("/assets/%{rest}.%{format}", status: 302)
  get "/static/github/:username/:project/*rest(.:format)", to: redirect("/assets/%{rest}.%{format}", status: 302)
  get "/js/*rest(.:format)", to: redirect("/assets/js/%{rest}.%{format}", status: 302)
  get "/css/*rest(.:format)", to: redirect("/assets/css/%{rest}.%{format}", status: 302)
  get "/images/*rest(.:format)", to: redirect("/assets/images/%{rest}.%{format}", status: 302)

  mount MissionControl::Jobs::Engine, at: "/jobs"
end
