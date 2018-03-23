Rails.application.routes.draw do
  get 'health_check', to: HealthChecksController.action(:new)
  namespace :ec2 do
    resources :metadata, only: %i[index]
    get '/metadata/:path', to: 'metadata#show', constraints: { path: /.*/ }
    root to: 'metadata#index'
  end
  resources :aliases, only: %i[new create update]
  root to: redirect('/ec2')
end
