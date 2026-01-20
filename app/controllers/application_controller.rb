class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?
  

  helper_method :current_api_token

  protected

  def configure_permitted_parameters
    case resource_class.name 
    when "Member"
      configure_member_params
    when "Librarian"
      configure_librarian_params  
    end
  end 

  def configure_member_params
    devise_parameter_sanitizer.permit(:sign_up ,keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :bio, :phone, :birth_date])
  end

  def configure_librarian_params
    devise_parameter_sanitizer.permit(:sign_up ,keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def after_sign_in_path_for(resource)
    case resource
    when Librarian
      librarians_dashboard_path
    when Member
      root_path
    else
      super
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  private

  def current_api_token

    user = current_member || current_librarian
    return nil unless user

 
    access_token = Doorkeeper::AccessToken.where(
      resource_owner_id: user.id,
      resource_owner_type: user.class.name,
      revoked_at: nil
    ).order(created_at: :desc).first

    if access_token && (access_token.expired? || !access_token.scopes.include?("public"))
      access_token.revoke 
      access_token = nil  
    end

    unless access_token
      access_token = Doorkeeper::AccessToken.create!(
        resource_owner_id: user.id,
        resource_owner_type: user.class.name,
        application_id: nil,
        scopes: "public", 
        expires_in: Doorkeeper.configuration.access_token_expires_in,
        use_refresh_token: false
      )
    end

    access_token.token
  end
end
