FactoryBot.define do
  factory :reservation do
    association :member
    
    book { association :book, available_copies: 0 }
    
    reservation_date { Date.today }
    status { :pending }

    trait :pending do
      status { :pending }
    end

    trait :fulfilled do
      status { :fulfilled }
      skip_availability_check { true }
    end

    trait :cancelled do
      status { :cancelled }
    end
  end
end