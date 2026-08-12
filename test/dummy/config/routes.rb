Rails.application.routes.draw do
  mount Consently::Engine => "/consently"

  root "pages#demo"
  get "demo" => "pages#demo"
  delete "demo/reset" => "pages#reset", as: :reset_demo
  get "cookies" => "pages#cookie_policy", as: :cookie_policy
  get "page" => "pages#show"
end
