require 'spec_helper'

describe_client_api Api::Client::V1::Comments do

  describe 'GET /timelines/:timeline_id/comments' do
    let!(:user) { create(:user) }

    before { logged_in(user) }

    it 'should have comments routable path' do
      timeline = create(:timeline, user: user)
      client_get "timelines/#{timeline.to_param}/comments", authentication_token: user.authentication_token, email: user.email
      expect(response.status).not_to eq(404)
    end

    it 'should respond with bad request in case of the missing auth params' do
      timeline = create(:timeline, user: user)
      client_get "timelines/#{timeline.to_param}/comments", authentication_token: user.authentication_token
      expect(response.status).to eq(400)
      client_get "timelines/#{timeline.to_param}/comments", email: user.email
      expect(response.status).to eq(400)
    end

    it 'should be successful on request with the valid credentials' do
      timeline = create(:timeline, user: user)
      client_get "timelines/#{timeline.to_param}/comments", authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(200)
    end

    it "should return list of the timeline comments" do
      timeline = create(:timeline, user: user)
      timeline.comments.destroy_all

      kate = create(:kate)
      fred = create(:fred)
      timeline.comments.create(comment: 'comment1', user: kate)
      timeline.comments.create(comment: 'comment2', user: fred)

      client_get "timelines/#{timeline.to_param}/comments", authentication_token: user.authentication_token, email: user.email
      json_response do |json|
        expect(json).to have(2).items

        json.each do |comment|
          expect(comment.keys).to include('id')
          expect(comment.keys).to include('comment')
          expect(comment.keys).to include('created_at')
          expect(comment.keys).to include('user_name')
          expect(comment.keys).to include('user_facebook_id')
          expect(comment.keys).to include('user_avatar_url')
          expect(comment.keys).to include('user_ext_id')
        end
      end
    end
  end

  describe 'POST /timelines/:timeline_id/comments' do
    let!(:user) { create(:user) }

    before { logged_in(user) }

    it 'creates new comment by current user' do
      timeline = create(:timeline, user: user)
      timeline.comments.destroy_all

      expect(timeline.comments).to be_empty

      client_post "timelines/#{timeline.to_param}/comments", authentication_token: user.authentication_token, email: user.email, comment: "Awesome!"

      json_response do |comment|
        expect(comment.keys).to include('id')
        expect(comment.keys).to include('comment')
        expect(comment.keys).to include('created_at')
        expect(comment.keys).to include('user_name')
        expect(comment.keys).to include('user_facebook_id')
        expect(comment.keys).to include('user_avatar_url')
        expect(comment.keys).to include('user_ext_id')
      end

      comments = timeline.reload.comments
      expect(comments).to have(1).item
      expect(comments[0].comment).to eq("Awesome!")
    end
  end

  describe 'DELETE /timelines/:timeline_id/comments/:id' do
    let!(:user) { create(:user) }

    before { logged_in(user) }

    it 'creates new comment by current user' do
      timeline = create(:timeline, user: user)
      timeline.comments.destroy_all

      kate = create(:kate)
      fred = create(:fred)
      comment1 = timeline.comments.create(comment: 'comment1', user: kate)
      comment2 = timeline.comments.create(comment: 'comment2', user: fred)

      client_delete "timelines/#{timeline.to_param}/comments/#{comment1.id}", authentication_token: user.authentication_token, email: user.email, comment: "Awesome!"

      comments = timeline.reload.comments
      expect(comments).to have(1).item
      expect(comments[0].comment).to eq(comment2.comment)
    end
  end
end
