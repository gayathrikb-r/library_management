# frozen_string_literal: true

class Members::PasswordsController < Devise::PasswordsController
  # POST /resource/password
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)

    # Always show the same message, regardless of whether the email exists
    if successfully_sent?(resource)
      flash[:notice] = "If your email exists in our system, you will receive reset instructions shortly."
    else
      flash[:notice] = "If your email exists in our system, you will receive reset instructions shortly."
    end

    redirect_to new_session_path(resource_name)
  end

  private

  def resource_params
    params.require(resource_name).permit(:email)
  end
end
