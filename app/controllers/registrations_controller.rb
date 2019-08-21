class RegistrationsController < Devise::RegistrationsController
  protected

  def after_sign_up_path_for(resource)
    creation_path
  end
end
