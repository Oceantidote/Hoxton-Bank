class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?


  def configure_permitted_parameters
    # For additional fields in app/views/devise/registrations/new.html.erb
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :middle_name, :last_name])

    # For additional in app/views/devise/registrations/edit.html.erb
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :middle_name, :last_name])
  end

  def headers
    {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "API-Key #{ENV['RAILS_BANK_API_KEY']}##{ENV['RAILS_BANK_SECRET_PATTERN']}"
    }
  end
end
