# spec/factories/promote_products.rb
FactoryBot.define do
  factory :promote_product do
    association :promotion  # Assumes you have a Promotion model
    association :product    # Assumes you have a Product model
    amount { Faker::Number.between(from: 1, to: 100) }  # Random amount between 1 and 100
  end
end
