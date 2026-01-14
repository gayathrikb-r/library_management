FactoryBot.define do
  factory :member do
    sequence(:email) { |n| "member#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    name { Faker::Name.name }
    
    phone { Faker::Number.leading_zero_number(digits: 10) } 
    
    bio { Faker::Lorem.paragraph }
    birth_date { Faker::Date.birthday(min_age: 18, max_age: 65) }

    trait :with_overdue_books do
      after(:create) do |member|
        create(:borrowing, :overdue, member: member)
      end
    end

    trait :with_active_borrowings do
      after(:create) do |member|
        create_list(:borrowing, 3, member: member)
      end
    end
  end
end