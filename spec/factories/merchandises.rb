# spec/factories/merchandises.rb
FactoryBot.define do
  factory :merchandise do
    association :product  # Assumes you have a Product model
    cut_off_value { Faker::Commerce.price(range: 10.0..1000.0) }  # Random cut off value
    promotion_end { Faker::Date.forward(days: 30) }  # Random promotion end date, 30 days in the future
    promotion_start { Faker::Date.forward(days: 30) }  # Random promotion end date, 30 days in th
  end
end
