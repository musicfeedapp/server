require 'spec_helper'

describe 'youtube' do

  it 'should get properties from facebook and app attributes for dead link' do
    fixture = JSON.parse(File.read(Settings.root_path.join('spec/integrations/youtube/fixtures/example1.json')))

    attributes = Aggregator::Providers::Youtube::Attributes.new(fixture)
    expect(attributes.name).to eq("Hassan El Shafei")
    expect(attributes.link).to eq("http://www.youtube.com/v/3dTGDvNwaEw")
    expect(attributes.picture).to eq("https://img.youtube.com/vi/3dTGDvNwaEw/hqdefault.jpg")
    expect(attributes.description).to eq("One of the best remixes I have ever heard in my life by Jon Hopkins Coldplay #TrackOfTheWeek\n\nhttps://www.youtube.com/watch?v=3dTGDvNwaEw")
    expect(attributes.artist).to eq("Hassan El Shafei")

    # add vcr to cover this case false => true because of no video anymore on youtube
    expect(attributes.valid?).to eq(false)
  end

end
