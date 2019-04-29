require 'spec_helper'

module Aggregator
  describe FacebookApplicationQueue do
    subject { Aggregator::FacebookApplicationQueue }

    before { subject.clear }

    before { allow(FacebookApplications).to receive(:facebook) { double(applications: ["something1:token1", "something2:token2", "something3:token3"]) }}

    it 'should use redis to as queue manager for applications list in the aggregator' do
      expect(subject.next).to eq("something3:token3")
      expect(Aggregator.redis.lrange(Aggregator::FacebookApplicationQueue::NAMESPACE, 0, -1).size).to eq(3)

      expect(subject.next).to eq("something2:token2")
      expect(subject.next).to eq("something1:token1")
      expect(subject.next).to eq("something3:token3")
    end
  end
end
