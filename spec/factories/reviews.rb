FactoryBot.define do
  factory :review do
    association :reviewer, factory: :member
    association :reviewable, factory: :book
    
    rating { rand(1..5) }
    comment { Faker::Lorem.paragraph(sentence_count: 3) }
    status { :pending }

    trait :pending do
      status { :pending }
    end

    trait :approved do
      status { :approved }
    end

    trait :flagged do
      status { :flagged }
    end

    trait :for_book do
      association :reviewable, factory: :book
    end

    trait :for_author do
      association :reviewable, factory: :author
    end
  end
end