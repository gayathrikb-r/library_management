FactoryBot.define do
  factory :category do

    sequence(:name) { |n| "#{Faker::Book.genre} #{n}" }

    trait :with_books do
      after(:create) do |category|
        create_list(:book, 5, categories: [category])
      end
    end
  end
end