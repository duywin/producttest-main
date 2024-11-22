# spec/factories/accounts.rb
FactoryBot.define do
  factory :account do
    email { "a1@emapho.com" }
    username { "auser12" }
    phonenumber { "01234567890" }
    address { "12 Finenish Street, Finland" }
    password { "Password@12" }
    gender { "male" }
    is_admin { false }

    # Devise fields
    encrypted_password { Devise::Encryptor.digest(Account, password) }
    reset_password_token { nil }
    reset_password_sent_at { nil }
    remember_created_at { nil }

    # Additional traits or states
    trait :admin do
      is_admin { true }
    end
  end
end
