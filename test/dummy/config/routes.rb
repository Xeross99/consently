Rails.application.routes.draw do
  mount Consently::Engine => "/consently"

  root "pages#demo"
  get "demo" => "pages#demo"
  delete "demo/reset" => "pages#reset", as: :reset_demo
  get "cookies" => "pages#cookie_policy", as: :cookie_policy
  get "page" => "pages#show"
  get "checkout" => "pages#checkout"
  get "cart" => "pages#cart"
  post "cart" => "pages#add_to_cart", as: :add_to_cart
  get "embeds" => "pages#embeds"
end
