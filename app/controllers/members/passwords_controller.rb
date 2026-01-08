# frozen_string_literal: true

class Members::PasswordsController < Devise::PasswordsController
  # POST /members/password
  def create
    self.resource = resource_class.send_reset_password_instructions(email_params)

    flash[:notice] =
      "If your email exists in our system, you will receive reset instructions shortly."

    redirect_to new_session_path(resource_name)
  end

  protected

  # ONLY for create
  def email_params
    params.require(resource_name).permit(:email)
  end
end
