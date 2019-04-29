require 'spec_helper'

describe UpdateFeedAppIconCountWorker do
  let!(:kate) { create(:kate, last_feed_viewed_at: 1.day.ago.to_datetime) }
  let!(:fred) { create(:fred) }


  it 'should tell users how many new activities been done against their profile' do
    kate.follow!(fred)

    timeline1 = create(:timeline, user: kate)
    timeline2 = create(:timeline, user: kate)
    timeline3 = create(:timeline, user: kate, created_at: 2.day.ago.to_datetime)

    fred_new_timeline = create(:timeline, user: fred)
    fred_old_timeline = create(:timeline, user: fred, created_at: 2.day.ago.to_datetime)

    # now we are not counting user likes
    fred.like!(timeline1)
    fred.like!(timeline2)

    allow_any_instance_of(Parse::Push).to receive(:save).and_return("200")

    feed_counter = UpdateFeedAppIconCountWorker::UserFeedCounter.new(kate)
    expect(feed_counter.perform).to eq(3)
    expect(feed_counter.followers_timelines).not_to include(fred_old_timeline)
  end

end
