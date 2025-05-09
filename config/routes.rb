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
  match "/:code", to: "errors#show", via: :all, constraints: ErrorsController.constraints

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

  %W[#{} search/ list/ static/].each do |prefix|
    get "#{prefix}docs/:name(/*rest)", to: "yard#featured", as: prefix.blank? ? "yard_featured" : nil, format: false
    get "#{prefix}stdlib/:name(/*rest)", to: "yard#stdlib", as: prefix.blank? ? "yard_stdlib" : nil, format: false
    get "#{prefix}gems/:name(/*rest)", to: "yard#gems", as: prefix.blank? ? "yard_gems" : nil, format: false
    get "#{prefix}github/:username/:project(/*rest(.:format))", to: "yard#github", as: prefix.blank? ? "yard_github" : nil,
      constraints: { username: /[a-z0-9_\.-]+/i, project: /[a-z0-9_\.-]+/i }, format: false
  end

  get "/js/*rest", to: redirect("/assets/js/%{rest}", status: 302), format: false
  get "/css/*rest", to: redirect("/assets/css/%{rest}", status: 302), format: false
  get "/images/*rest", to: redirect("/assets/images/%{rest}", status: 302), format: false

  mount MissionControl::Jobs::Engine, at: "/jobs"
end
