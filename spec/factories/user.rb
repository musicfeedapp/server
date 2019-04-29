FactoryGirl.define do
  factory :user do
    email
    password              "12345678"
    password_confirmation "12345678"
    facebook_id
    facebook_link 'http://www.facebook.com/0'
    user_type    'user'
    name
    username

    after(:create) do |user|
      create(:facebook_authentication, user: user)
    end
  end

  factory :admin, parent: :user do
    role 'admin'
  end

  factory :kate, parent: :user do
    first_name   'Kate'
    last_name    'Watson'
    facebook_id  '1'
  end

  factory :fred, parent: :user do
    first_name   'Fred'
    last_name    'Bond'
    facebook_id  '3'
  end

  factory :mario, parent: :user do
    first_name   'Mario'
    last_name    'Brother'
    facebook_id  '4'
  end


  sequence(:facebook_id) { |i| "unique-facebook-id-#{i}" }
  sequence(:email) { |i| "admin#{i}@rubyforce.com" }
  sequence(:username) { |i| "Zoro#{i}" }
  sequence(:name) { |i| "Zoro Name#{i}" }
end

