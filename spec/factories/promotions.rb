# spec/factories/promotions.rb
FactoryBot.define do
  factory :promotion do
    promote_code { Faker::Alphanumeric.alphanumeric(number: 10) }  # Random code, e.g., "XYS890ABC"
    promotion_type { %w[discount percentage].sample }  # Randomly selects between 'discount' and 'percentage'
    apply_field { %w[product category order].sample }  # Random apply field
    value { Faker::Number.decimal(l_digits: 2) }  # Random decimal value
    end_date { Faker::Date.forward(days: 30) }  # Random end date within the next 30 days
    min_quantity { Faker::Number.between(from: 1, to: 10) }  # Random minimum quantity between 1 and 10
  end
end
