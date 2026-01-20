FactoryBot.define do
  factory :book do
    title { Faker::Book.title }
     sequence(:isbn) { |n| "978-X-#{sprintf('%09d', n)}" }
    publication_year { rand(1900..2024) }
    total_copies { 5 }
    description { Faker::Lorem.paragraph }

    trait :unavailable do
      available_copies { 0 }
    end

    trait :with_authors do
      after(:create) do |book|
        create_list(:author, 2, books: [book])
      end
    end

    trait :with_categories do
      after(:create) do |book|
        create_list(:category, 2, books: [book])
      end
    end

    trait :with_reviews do
      after(:create) do |book|
        create_list(:review, 3, reviewable: book, status: :approved)
      end
    end
  end
end