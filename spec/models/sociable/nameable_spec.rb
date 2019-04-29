require 'spec_helper'

describe User do

  describe '#name' do
    it 'should return existing name' do
      user = create(:user, name: 'Alex Korsak')
      user.reload

      expect(user.name).to eq('Alex Korsak')
      expect(user.first_name).to eq('Alex')
      expect(user.last_name).to eq('Korsak')

      user = create(:user, name: nil, first_name: 'Bob', last_name: 'Marley')
      expect(user.name).to eq('Bob Marley')
      expect(user.first_name).to eq('Bob')
      expect(user.last_name).to eq('Marley')
    end
  end
end

