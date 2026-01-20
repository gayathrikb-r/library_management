# config/initializers/doorkeeper.rb
Doorkeeper.configure do
  orm :active_record
  use_polymorphic_resource_owner 
  
 resource_owner_authenticator do
    # Try to get the current member or librarian from the browser session
    current_member || current_librarian || redirect_to(new_member_session_path)
  end

  # --- FIX 1: Use Librarian instead of AdminUser (since you don't have an Admin model) ---
  admin_authenticator do
    current_librarian || redirect_to(new_librarian_session_path)
  end

  authorization_code_expires_in 10.minutes
  access_token_expires_in 2.hours
  use_refresh_token
  
  reuse_access_token 
  
  # ------------------------------------------------------------------
  # 2. FOR API LOGIN (Password Grant)
  # This runs when you send a POST request with username/password.
  # ------------------------------------------------------------------
  resource_owner_from_credentials do |_routes|
    user_type = params[:user_type]&.downcase
    
    user = case user_type
    when 'member'
      Member.find_for_database_authentication(email: params[:username])
    when 'librarian'
      Librarian.find_for_database_authentication(email: params[:username])
    else
      Member.find_for_database_authentication(email: params[:username]) || 
      Librarian.find_for_database_authentication(email: params[:username])
    end

    if user && user.valid_password?(params[:password])
      user
    end
  end
  
  skip_authorization { true }
  
  # Allow all necessary flows including Client Credentials
  grant_flows %w[authorization_code client_credentials password refresh_token]

  default_scopes :public
  optional_scopes :member, :librarian

  realm "Library API"
  
  force_ssl_in_redirect_uri Rails.env.production?
end