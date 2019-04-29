require 'spec_helper'

describe User do
  it 'should gereate authentication token on save' do
    user = build(:user)
    expect(user.authentication_token).not_to be
    user.save!
    expect(user.reload.authentication_token).to be
  end
end

