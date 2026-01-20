FactoryBot.define do
  factory :book_category do
    association :book
    association :category
  end
end