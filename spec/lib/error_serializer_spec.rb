require 'spec_helper'

describe ErrorSerializer do

  it 'should be empty in case of nothing' do
    errors = ErrorSerializer.serialize(nil)
    expect(errors).to eq({})
  end

  it 'should generate errors messages for models' do
    user = User.new
    user.valid?

    errors = ErrorSerializer.serialize(user.errors)
    expect(errors).to eq({
      errors: [
        { id: :email, title: "Email can't be blank." },
        { id: :password, title: "Password can't be blank." },
      ]
    })
  end

end

