# spec/factories/carts.rb
FactoryBot.define do
  factory :cart do
    association :account  # Assuming you have an Account model
    check_out { [true, false].sample }  # Random boolean for check_out
    total_price { Faker::Number.between(from: 1000, to: 5000) }  # Random total price
    quantity { Faker::Number.between(from: 1, to: 10) }  # Random quantity of items
    address { Faker::Address.full_address }  # Random address
    status { ['pending', 'delivering', 'delivered', 'canceled'].sample }  # Random status
    deliver_day { Faker::Date.forward(days: 10) }  # Random delivery date 10 days in the future

    # Additional traits or customization can be added if needed
  end
end
