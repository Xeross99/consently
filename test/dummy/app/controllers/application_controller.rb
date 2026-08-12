class ApplicationController < ActionController::Base
  around_action :switch_locale

  private

  # The banner has to follow the page it sits on, so the tests need a way to
  # ask for one.
  def switch_locale(&action)
    I18n.with_locale(params[:locale].presence || I18n.default_locale, &action)
  end
end
