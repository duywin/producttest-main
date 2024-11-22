# spec/factories/cart_items.rb
FactoryBot.define do
  factory :cart_item do
    association :cart  # Assumes you have a Cart model
    association :product  # Assumes you have a Product model
    quantity { Faker::Number.between(from: 1, to: 5) }
    is_anomaly { [true, false].sample }
    price { Faker::Commerce.price(range: 1.0..100.0) }

    # You can add other attributes as needed
  end
end
