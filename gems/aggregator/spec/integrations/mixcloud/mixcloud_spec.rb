require 'spec_helper'
require 'json'

describe 'mixcloud' do

  it 'should find url with full mp3 track on the page' do
    url = "https://www.mixcloud.com/juanramongimenezsanchez36/secret-music-1/"
    fixture = File.read(Settings.root_path.join('spec/integrations/mixcloud/fixtures/example1.html'))

    allow(Faraday).to receive(:get).with(url) { double('response', body: fixture) }

    attributes = Aggregator::Providers::Mixcloud::Attributes.new('link' => url)
    expect(attributes.picture).to eq("http://thumbnail.mixcloud.com/w/400/h/400/q/85/upload/images/extaudio/a82d3289-2be1-4860-801b-5e704c0a5a0f.jpg")
    expect(attributes.stream).to eq("https://stream16.mixcloud.com/c/originals/5/f/2/4/0a0a-aa86-4ad4-9c59-d443bfae6be0.mp3")
  end
end
