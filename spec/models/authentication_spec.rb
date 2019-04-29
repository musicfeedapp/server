require 'spec_helper'

describe Authentication do
  describe '.find_user_by_auth' do
    let!(:kate) { create(:authentication, email: 'kate@example.com', provider: 'google', uid: 'google-id') }
    let!(:kate) { create(:authentication, email: 'kate@example.com', provider: 'linkedin', uid: 'linkedin-id') }
    let!(:fred) { create(:authentication, email: 'fred@example.com', provider: 'facebook', uid: 'facebook-id') }
    let(:expires_at) { Time.now.to_i }
    let(:auth) { double('auth', credentials: { expires_at: expires_at, token: 'auth-token' }, provider: 'facebook', uid: 'facebook-id', info: { 'email' => 'fred@example.com' }) }

    before do
      @user = Authentication.find_user_by_auth(auth)
    end

    it 'should be possible to find people by auth' do
      expect(@user).to eq(fred.user)
    end

    it 'shoud set the latest authentication attributes' do
      authentication = @user.reload.authentications.last
      expect(authentication.auth_token).to eq('auth-token')
      expect(authentication.expires_at).to eq(Time.at(expires_at))
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
