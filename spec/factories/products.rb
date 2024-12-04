# spec/factories/products.rb
require "faker"
FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    product_type { "Yoga" }
    prices { Faker::Commerce.price(range: 10.0..100.0).to_s }
    desc { Faker::Lorem.paragraph(sentence_count: 3) }
    stock { Faker::Number.between(from: 1, to: 100) }
    picture { Faker::LoremFlickr.image(size: "300x300", search_terms: ['product']) }
    picture_file { nil } # Set this to nil initially or provide a default file path
  end
end
