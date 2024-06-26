Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  post '/track_shipment', to: 'shipments#track_shipment'
  post '/aftership', to: 'shipments#aftership'
  post '/create_trackings', to: 'shipments#create_trackings'

  resources :users
  resources :shipments do
    post 'aftership', on: :collection
  end
  # Defines the root path route ("/")
  # root "posts#index"
end
