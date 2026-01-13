Doorkeeper.configure do
  orm :active_record
  use_polymorphic_resource_owner 
  
  resource_owner_authenticator do
    nil  # Not used for password grant
  end

  admin_authenticator do
    current_admin_user || redirect_to(new_admin_user_session_path)
  end

  authorization_code_expires_in 10.minutes
  access_token_expires_in 2.hours
  use_refresh_token
  reuse_access_token
  
  # PASSWORD GRANT (Postman/API clients)
  resource_owner_from_credentials do |_routes|
    # Get user_type from params
    user_type = params[:user_type]&.downcase
    
    user = case user_type
    when 'member'
      Member.find_by(email: params[:username])
    when 'librarian'
      Librarian.find_by(email: params[:username])
    else
      # Try both if user_type not specified (backward compatibility)
      Member.find_by(email: params[:username]) || 
      Librarian.find_by(email: params[:username])
    end

    # Validate password and return user
    user if user&.valid_password?(params[:password])
  end
  
  # Skip authorization screen
  skip_authorization { true }
  
  # Only allow password grant
  grant_flows %w[password]

  default_scopes :public
  optional_scopes :member, :librarian

  realm "Library API"
  
  # Force SSL in production
  force_ssl_in_redirect_uri Rails.env.production?
end