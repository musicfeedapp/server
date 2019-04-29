class Authentication < ActiveRecord::Base
  belongs_to :user

  validates :provider, :uid, :email, :user_id, presence: true

  def self.find_user_by_auth(auth)
    authentication = where(provider:  auth.provider).
                     where(uid:       auth.uid).
                     where(email:     auth.info['email']).
                     first

    if authentication.present?
      authentication.update_attributes!(
        auth_token: auth.credentials[:token],
        expires_at: Time.at(auth.credentials[:expires_at]))
      authentication.user
    end
  end
end

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
