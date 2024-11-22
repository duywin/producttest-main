# spec/factories/categories.rb
FactoryBot.define do
  factory :category do
    name { Faker::Commerce.department } # Random category name, e.g., "Electronics"
    total { Faker::Number.between(from: 1, to: 100) } # Random total number

    # You can also add traits or more complex data generation if necessary
  end
end
