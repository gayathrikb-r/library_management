FactoryBot.define do
  factory :librarian do
    sequence(:email) { |n| "librarian#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    name { Faker::Name.name }
    phone { '9876543210' } 
  end
end