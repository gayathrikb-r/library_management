
FactoryBot.define do
  factory :borrowing do
    association :book
    association :member

    borrowed_date { Date.current }
    due_date { 2.weeks.from_now.to_date }
    status { :borrowed }
    returned_date { nil }

    trait :active do
      status { :borrowed }
      returned_date { nil }
    end

    trait :returned do
      status { :returned }
      returned_date { Date.current }
    end

    trait :overdue do
      status { :overdue }
      borrowed_date { 1.month.ago.to_date }
      due_date { 1.week.ago.to_date }
      returned_date { nil }
    end
  end
end
