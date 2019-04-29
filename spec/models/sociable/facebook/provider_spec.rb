require 'spec_helper'

describe Socialable::Facebook::Provider do
  let(:provider) { Socialable::Facebook::Provider.new(authentication) }

  describe '.expired?' do
    context 'when is not expired' do
      let(:authentication) { double('authentication', expires_at: 3.days.from_now) }

      it { expect(provider).not_to be_expired }
    end

    context 'when is expired example 1' do
      let(:authentication) { double('authentication', expires_at: 1.day.ago) }

      it { expect(provider).to be_expired }
    end

    context 'when is expired example 2' do
      let(:authentication) { double('authentication', expires_at: 2.hours.ago) }

      it { expect(provider).to be_expired }
    end
  end

  describe '.auth_token' do
    let(:authentication) { double('authentication', expires_at: 3.days.from_now, auth_token: 'facebook-token') }

    before do
      allow(provider).to receive(:regenerate_auth_token) { 'new-facebook-token' }
    end

    it 'should regenerate auth token in case of expired' do
      expect(provider.auth_token).to eq('facebook-token')
      allow(provider).to receive(:expired?) { true }
      expect(provider.auth_token).to eq('new-facebook-token')
    end
  end

  describe '.regenerate_auth_token' do
    let(:expires_at) { 2.days.ago }
    let(:authentication) { create(:authentication, auth_token: 'auth-token', expires_at: expires_at) }
    let(:now) { DateTime.now }

    before do
      expect(provider).to receive_message_chain(:oauth, :exchange_access_token_info).
                           with(authentication.auth_token).
                           and_return(auth_token: 'new-auth-token', expires_at: now)
    end

    it 'should set last_expires_at as the previous date on updates' do
      provider.regenerate_auth_token
      expect(authentication.reload.expires_at.to_date).to eq(now.to_date)
      expect(authentication.reload.last_expires_at.to_date).to eq(expires_at.to_date)
    end
  end
end
