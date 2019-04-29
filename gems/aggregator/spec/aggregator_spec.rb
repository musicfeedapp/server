require 'spec_helper'

describe Aggregator do
  it 'has a version number' do
    expect(Aggregator::VERSION).not_to be nil
  end

  it 'has providers collection for accessing outside of gem' do
    expect(Aggregator.providers).to eq([
      Aggregator::Providers::Grooveshark::Link,
      Aggregator::Providers::Mixcloud::Link,
      Aggregator::Providers::Shazam::Link,
      Aggregator::Providers::Soundcloud::Link,
      Aggregator::Providers::Spotify::Link,
      Aggregator::Providers::Youtube::Link
    ])
  end

  it 'should use mnesia for god sake' do
    id = Aggregator.client.set("test1" => "value1")
    expect(id.to_i > 0).to eq(true)

    attributes = Aggregator.client.get(id)
    expect(attributes['test1']).to eq("value1")

    Aggregator.client.del(id)
  end
end
