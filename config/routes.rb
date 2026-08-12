Consently::Engine.routes.draw do
  # Only needed when config.log_consents is on. Mount the engine and the
  # banner will POST each decision here as proof of consent.
  resource :consents, only: :create
end
