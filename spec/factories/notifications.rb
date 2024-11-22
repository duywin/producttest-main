# spec/factories/notifications.rb
FactoryBot.define do
  factory :notification do
    admin_id {"1"}
    message { Faker::Lorem.sentence }  # Random message
    link { Faker::Internet.url }  # Random link
    read { [true, false].sample }  # Random read status
  end
end
