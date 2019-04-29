require 'spec_helper'

require 'sidekiq/testing'

describe User do
  before do
    client = User.__elasticsearch__.client

    if client.indices.exists(index: 'users-test')
      client.indices.delete(index: 'users-test')
    end
  end

  describe '#search_contacts' do
    let(:contact_list) { [{ email: "test1@test.com", contact_number: "+123456789" }, { contact_number: "375 (29) 123-85-42" }, { contact_number: "+03224713082" }] }

    before do
      Sidekiq::Testing.inline! do
        @user1 = create(:user, email: "test1@gmail.com", secondary_phones: ["+123456789"])
        @user2 = create(:user, email: "test2@test.com", secondary_phones: ["375 (29) 123-85-42"])
        @user3 = create(:user, email: "test3@test.com", secondary_phones: ["+1232131211", "+03224713082"])

        @phone_not_found_user = create(:user, email: "test4@test.com", secondary_phones: ["+132132112"])
        @not_included_email_user = create(:user, email: "noincluded@test.com")

        @user5 = create(:user, contact_list: contact_list)
      end
    end

    it "should should return the matched users based on email and secondary phones" do
      sleep(5)
      result = @user5.search_contacts.records.reload.to_a

      expect(result.count).to eq(3)

      expect(result).not_to include(@phone_not_found_user)
      expect(result).not_to include(@not_included_email_user)
    end
  end
end
