# Pinned for the host application, so `import "consently/banner_controller"`
# resolves without anyone editing config/importmap.rb.
pin "consently/banner_controller", to: "consently/banner_controller.js", preload: true
pin "consently/embed_controller", to: "consently/embed_controller.js", preload: true
pin "consently/events", to: "consently/events.js", preload: true
