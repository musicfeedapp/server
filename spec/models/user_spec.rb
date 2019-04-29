require 'spec_helper'

describe User, broken: true do
  describe '#role?' do
    describe '#admin' do
      let(:admin) { create(:user, role: 'admin') }

      it 'should be admin' do
        expect(admin.role?(:admin)).to  eq(true)
        expect(admin.role?('admin')).to eq(true)
      end
    end

    context '#user' do
      let(:user) { create(:user, role: 'user') }

      it 'should be normal user' do
        expect(user.role?(:admin)).to be_falsey
      end
    end
  end
end

describe User do
  before do
    allow_any_instance_of(Socialable::Facebook::Provider).to receive(:client) { double('client', get_object: { 'cover' => { 'source' => 'image.jpg' }, 'username' => 'john.watson' }) }
  end

  describe '#find_for_facebook' do
    context 'with valid auth' do
      let(:expires_at) { Time.now.to_i }

      before do
        @auth = double('auth', credentials: { token: 'auth-token', expires_at: expires_at }, provider: 'facebook', uid: 'facebook-id', extra: { 'raw_info' => { 'name' => 'John Watson', 'picture' => 'example.jpg' } }, info: { 'email' => 'john.watson@example.com', 'urls' => { 'Facebook' => 'http://facebook.com' } })
      end

      it 'should create a new user by facebook auth' do
        @user = User.find_for_facebook(nil, @auth)
        expect(User.count).to  eq(1)
        expect(@user.name).to  eq("John Watson")
        expect(@user.email).to eq("john.watson@example.com")
        expect(@user.facebook_link).to eq("http://facebook.com")
      end

      it 'should create facebook authentication' do
        @user = User.find_for_facebook(nil, @auth)
        authentications = @user.reload.authentications
        expect(authentications).to have(1).item
        expect(authentications[0].provider).to eq('facebook')
        expect(authentications[0].uid).to      eq('facebook-id')
        expect(authentications[0].auth_token).to eq('auth-token')
      end
    end

    context 'with invalid auth' do
      before do
        @auth = double('auth', credentials: { token: 'auth-token' }, provider: 'facebook', uid: 'uid', extra: { 'raw_info' => { 'name' => '', 'picture' => 'examle.jpg' } }, info: { 'email' => '', 'urls' => { 'Facebook' => 'http://facebook.com' } })
        @user = User.find_for_facebook(nil, @auth)
      end

      it 'should not create a new user' do
        expect(User.count).to eq(0)
      end

      it 'should not create a authentication' do
        expect(Authentication.count).to eq(0)
      end
    end
  end
end

describe User do
  describe '.name' do
    let(:user) { build(:user, name: nil, first_name: "James", middle_name: "Petrovich", last_name: "Bond") }

    it 'should return full name based on first, middle, last names' do
      expect(user.name).to eq("James Bond Petrovich")
    end
  end

  describe '.name=(value)' do
    let(:user) { build(:user) }

    it 'should not assign anything in case of noname' do
      user.name = nil
      expect(user.first_name).not_to be
      expect(user.last_name).not_to be
      expect(user.middle_name).not_to be
    end

    it 'should assign first, middle, last names using passed full name' do
      user.name = "Kate"
      expect(user.first_name).to eq("Kate")
      expect(user.last_name).not_to be
      expect(user.middle_name).not_to be

      user.name = "Kate Watson"
      expect(user.first_name).to eq("Kate")
      expect(user.last_name).to eq("Watson")
      expect(user.middle_name).not_to be

      user.name = "Kate Watson Petrovna"
      expect(user.first_name).to eq("Kate")
      expect(user.last_name).to eq("Watson")
      expect(user.middle_name).to eq("Petrovna")
    end
  end
end

describe User do
  let(:user) { create(:user) }

  describe 'authentications.facebook.auth_token' do
    context 'with authentication' do
      before do
        create(:authentication, user: user, provider: 'facebook', auth_token: 'facebook-token')
        create(:authentication, user: user, provider: 'twitter', auth_token: 'twitter-token')
      end

      it 'should be possible to get facebook auth token' do

      end
    end

    context 'no authentication' do
      it 'should be possible to skip auth token' do

      end
    end
  end
end

# == Schema Information
#
# Table name: users
#
#  id                                :integer          not null, primary key
#  email                             :string(255)      default(""), not null
#  encrypted_password                :string(255)      default(""), not null
#  reset_password_token              :string(255)
#  reset_password_sent_at            :datetime
#  remember_created_at               :datetime
#  sign_in_count                     :integer          default(0)
#  current_sign_in_at                :datetime
#  last_sign_in_at                   :datetime
#  current_sign_in_ip                :string(255)
#  last_sign_in_ip                   :string(255)
#  created_at                        :datetime
#  updated_at                        :datetime
#  role                              :string(255)
#  avatar                            :string(255)
#  first_name                        :string(255)
#  middle_name                       :string(255)
#  last_name                         :string(255)
#  facebook_link                     :string(255)
#  twitter_link                      :string(255)
#  google_plus_link                  :string(255)
#  linkedin_link                     :string(255)
#  facebook_avatar                   :string(255)
#  google_plus_avatar                :string(255)
#  linkedin_avatar                   :string(255)
#  authentication_token              :string(255)
#  facebook_profile_image_url        :string(255)
#  facebook_id                       :string(255)
#  background                        :string(255)
#  username                          :string
#  comments_count                    :integer          default(0)
#  enabled                           :boolean          default(TRUE)
#  website                           :text             default("0")
#  genres                            :text             default([]), is an Array
#  user_type                         :string(255)      default("user"), not null
#  followers_count                   :integer          default(0)
#  followed_count                    :integer          default(0)
#  friends_count                     :integer          default(0)
#  name                              :string(255)      not null
#  is_verified                       :boolean          default(FALSE)
#  ext_id                            :string
#  restricted_timelines              :integer          default([]), is an Array
#  restricted_users                  :string           default([]), is an Array
#  welcome_notified_at               :datetime
#  category                          :string
#  public_playlists_timelines_count  :integer          default(0)
#  private_playlists_timelines_count :integer          default(0)
#  aggregated_at                     :datetime
#  suggestions_count                 :integer          default(0)
#  contact_number                    :string
#  contact_list                      :hstore           default([]), is an Array
#  phone_artists                     :hstore           default([]), is an Array
#  device_id                         :string
#  last_feed_viewed_at               :datetime         default(Thu, 03 Dec 2015 09:09:51 UTC +00:00)
#  secondary_emails                  :text             default([]), is an Array
#  secondary_phones                  :text             default([]), is an Array
#  login_method                      :string
#  timelines_count                   :integer          default(0)
#  restricted_suggestions            :text             default([]), is an Array
#
# Indexes
#
#  index_users_on_authentication_token  (authentication_token) UNIQUE
#  index_users_on_category              (category)
#  index_users_on_created_at            (created_at)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_enabled               (enabled)
#  index_users_on_ext_id                (ext_id)
#  index_users_on_facebook_id           (facebook_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_user_type             (user_type)
#  index_users_on_username              (username)
#
