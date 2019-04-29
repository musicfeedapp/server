require 'spec_helper'

describe 'spotify' do

  it 'should get properties from facebook and app attributes' do
    fixture = JSON.parse(File.read(Settings.root_path.join('spec/integrations/spotify/fixtures/example1.json')))

    attributes = Aggregator::Providers::Spotify::Attributes.new(fixture)
    expect(attributes.name).to eq("Let Me Go")
    expect(attributes.link).to eq("http://open.spotify.com/track/6A1yZW5SLd9hpLZsG29hCQ")
    expect(attributes.picture).to eq("https://i.scdn.co/image/942a7b5a992b704f4b5115198672567916047526")
    expect(attributes.description).to eq("Let Me Go, a song by 3 Doors Down on Spotify")
    expect(attributes.artist).to eq("3 Doors Down")

    # no track in soundcloud by this url.
    expect(attributes.valid?).to eq(true)
  end

  it 'should build timeline object based on the spotify attributes' do
    fixture = JSON.parse(File.read(Settings.root_path.join('spec/integrations/spotify/fixtures/example1.json')))

    facebook_attributes = fixture
    spotify_attributes = fixture

    timeline = Aggregator::Providers::Spotify::Finder.find(facebook_attributes, spotify_attributes)
    expect(timeline.name).to eq("Let Me Go")
  end

end
