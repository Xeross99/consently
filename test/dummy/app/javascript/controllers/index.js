import { application } from "controllers/application"

// Exactly what `rails g consently:install` writes into a host application.
import ConsentlyBannerController from "consently/banner_controller"
application.register("consently-banner", ConsentlyBannerController)
