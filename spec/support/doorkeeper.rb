# spec/support/doorkeeper.rb
module DoorkeeperHelpers
  def create_doorkeeper_app
    @application ||= Doorkeeper::Application.create!(
      name: "Test Application",
      redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
      scopes: "public member librarian"
    )
  end

  def create_access_token(resource_owner, scopes: 'public')
    create_doorkeeper_app
    
    Doorkeeper::AccessToken.create!(
      application: @application,
      resource_owner_id: resource_owner.id,
      resource_owner_type: resource_owner.class.name,
      scopes: scopes,
      expires_in: 2.hours
    )
  end

  def api_headers_with_token(token)
    {
      'Authorization' => "Bearer #{token.token}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end
end

RSpec.configure do |config|
  config.include DoorkeeperHelpers, type: :request
end