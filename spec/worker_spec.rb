require 'spec_helper'

describe 'perform push to queue for any worker' do

  class Klass
    include Sidekiq::Worker

    def perform(attributes)
      puts attributes
    end
  end

  it 'should add utf8 characters to the queue' do
    test = "<i>[Repost]</i> \xE2\x86\xBB button!</b>"
    expect {
      Klass.perform_async(test)
    }.not_to raise_error

    test_attributes = { test: test }
    expect {
      Klass.perform_async(test_attributes)
    }.not_to raise_error

    test_collection = [{ test: test }]
    expect {
      Klass.perform_async(test_collection)
    }.not_to raise_error
  end
end
