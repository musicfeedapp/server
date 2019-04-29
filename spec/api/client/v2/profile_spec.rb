 require 'spec_helper'

 require 'spec_helper'

 module Api
   module Client
     module V2

       describe_client_api Profile do

         describe 'GET /v2/profile/show?username=<ext_id>' do
           let!(:user) { create(:user) }

           before { logged_in(user) }

          it 'should get user friends and is_followed flag as dependency for current user' do
             kate = create(:kate)
             fred = create(:fred)

             user.follow!(kate)
             kate.follow!(fred)
             kate.friend!(fred)

             v2_client_get "profile/show", authentication_token: user.authentication_token, email: user.email, username: kate.ext_id
             expect(response.status).to eq(200)
             json_response do |attributes|
              expect(attributes['is_followed']).to eq(true)
              expect(attributes['followed'].to_a.size).to eq(1)
              expect(attributes['followed'][0]['username']).to eq(user.username)
              expect(attributes['followings']['friends'].to_a.size).to eq(1)
              expect(attributes['followings']['friends'][0]['username']).to eq(fred.username)
              expect(attributes['followings']['friends'][0]['is_followed']).to eq(false)
             end

             v2_client_get "profile/show", authentication_token: user.authentication_token, email: user.email, username: fred.ext_id
             expect(response.status).to eq(200)
             json_response do |attributes|
               expect(attributes['is_followed']).to eq(false)
               expect(attributes['followed'].to_a.size).to eq(1)
               expect(attributes['followed'][0]['username']).to eq(kate.username)
             end

            v2_client_get "profile/show", authentication_token: user.authentication_token, email: user.email, username: user.ext_id
             expect(response.status).to eq(200)
             json_response do |attributes|
              expect(attributes['is_followed']).to eq(true)
              expect(attributes['followings']['friends'].to_a.size).to eq(1)
              expect(attributes['followings']['friends'][0]['is_followed']).to eq(true)
              expect(attributes['followings']['friends'][0]['username']).to eq(kate.username)
             end
           end
         end

       end

     end
   end
 end
