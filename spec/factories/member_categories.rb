FactoryBot.define do
  factory :member_category do
    association :member
    association :category
  end
end