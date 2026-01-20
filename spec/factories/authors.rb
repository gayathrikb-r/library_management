FactoryBot.define do
  factory :author do
    name { Faker::Book.author }
    
    biography { Faker::Lorem.paragraph(sentence_count: 5) }
    birth_date { Faker::Date.birthday(min_age: 30, max_age: 90) }

    trait :with_books do
      after(:create) do |author|
        create_list(:book, 3, authors: [author])
      end
    end
  end
end