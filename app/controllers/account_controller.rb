# frozen_string_literal: true

# Devise User Controller
class AccountController < Devise::RegistrationsController
  before_action :require_no_sso!, only: %i[new create]

  def new
    super
  end

  def edit
    redirect_to setting_path
  end

  # POST /resource
  def create
    build_resource(sign_up_params)
    resource.login = params[resource_name][:login]
    resource.email = params[resource_name][:email]
    if verify_rucaptcha?(resource) && resource.save

      if resource.active_for_authentication?
        sign_in(resource_name, resource)
      else
        user_flash_msg
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    end
  end


  private

    # Overwrite the default url to be used after updating a resource.
    # It should be edit_user_registration_path
    # Note: resource param can't miss, because it's the super caller way.
    def after_update_path_for(_)
      edit_user_registration_path
    end

  def after_inactive_sign_up_path_for(resource)
    new_user_session_path
  end

  def user_flash_msg
    if resource.inactive_message == :unconfirmed
      set_flash_message :warning, :"signed_up_but_unconfirmed", email: resource.email
    else
      set_flash_message :warning, :"signed_up_but_#{resource.inactive_message}"
    end
  end
end
