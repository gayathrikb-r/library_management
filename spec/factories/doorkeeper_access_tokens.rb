FactoryBot.define do
  factory :access_token, class: 'Doorkeeper::AccessToken' do
   
    association :application, factory: :doorkeeper_application
    
    expires_in { 2.hours }
    scopes { 'public' }
  end
end