# == Schema Information
#
# Table name: authentications
#
#  id              :integer          not null, primary key
#  provider        :string(255)      not null
#  uid             :string(255)      not null
#  email           :string(255)      not null
#  user_id         :integer          not null
#  created_at      :datetime
#  updated_at      :datetime
#  auth_token      :text
#  expires_at      :datetime
#  last_expires_at :datetime
#
# Indexes
#
#  index_authentications_on_email                       (email)
#  index_authentications_on_provider                    (provider)
#  index_authentications_on_provider_and_uid_and_email  (provider,uid,email)
#  index_authentications_on_uid                         (uid)
#  index_authentications_on_user_id                     (user_id)
#  index_authentications_on_user_id_and_provider        (user_id,provider)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :authentication do
    provider "provider"
    uid      "provider-id"
    email    "user@example.com"
    user     { create(:user) }
  end

  factory :facebook_authentication, parent: :authentication do
    provider    'facebook'
    uid         'good-uid'
    email       'man@example.com'
    expires_at  { 3.days.from_now }
  end
end
