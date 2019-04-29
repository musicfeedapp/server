require 'spec_helper'

require 'json'

describe 'soundcloud' do

  it 'should collect properties from facebook attributes and no more from soundcloud because of dead link' do
    fixture = JSON.parse(File.read(Settings.root_path.join('spec/integrations/soundcloud/fixtures/example1.json')))

    attributes = Aggregator::Providers::Soundcloud::Attributes.new(fixture)
    expect(attributes.name).to eq("Back To Dust (Jimmy Edgar Remix)")
    expect(attributes.link).to eq("http://soundcloud.com/getpeople/back-to-dust-jimmy-edgar-remix")
    expect(attributes.picture).to eq("https://fbexternal-a.akamaihd.net/safe_image.php?d=AQA8MsEedMNhzwhj&w=130&h=130&url=http%3A%2F%2Fi1.sndcdn.com%2Fartworks-000033156834-3lpuoz-t300x300.jpg%3F2479809&cfs=1")
    expect(attributes.description).to eq("FACT MAGAZINE: http://www.factmag.com/2012/11/12/premiere-jimmy-edgar-gives-shoegazers-get-people-a-glitzy-overhaul/  'Back To Dust' is out Novembe...")
    expect(attributes.artist).to eq(nil)

    # no track in soundcloud by this url.
    expect(attributes.valid?).to eq(false)
  end

  context "when artwork is present" do
    it 'should get properties from facebook and soundcloud attributes' do
      fixture = JSON.parse(File.read(Settings.root_path.join('spec/integrations/soundcloud/fixtures/example2.json')))

      attributes = Aggregator::Providers::Soundcloud::Attributes.new(fixture)
      expect(attributes.name).to eq("Vexaic - Soar The Skies")
      expect(attributes.link).to eq("http://soundcloud.com/vexaic/vexaic-soar-the-skies")
      expect(attributes.picture).to eq("https://i1.sndcdn.com/artworks-000119291885-duvk2k-t500x500.jpg")
      expect(attributes.description).to eq("Finished this three months ago, one of the project's I had backed up on a USB. This sits at 120bpm with a Chillstep drop towards the end. If you can wait until the drop hits, I'm 99% sure you'll feel something.")
      expect(attributes.artist).to eq("Vexaic")

      expect(attributes.valid?).to eq(true)
    end
  end

  context "when artwork is not present" do
    it 'should get properties from facebook and soundcloud attributes' do
      fixture = JSON.parse(File.read(Settings.root_path.join('spec/integrations/soundcloud/fixtures/example3.json')))

      attributes = Aggregator::Providers::Soundcloud::Attributes.new(fixture)
      expect(attributes.name).to eq("swami~harami - Never give up")
      expect(attributes.link).to eq("http://soundcloud.com/swami-harami/never-give-up")
      expect(attributes.picture).to eq("https://i1.sndcdn.com/avatars-000068172738-exslk8-t500x500.jpg")
      expect(attributes.description).to eq("Finished this three months ago, one of the project's I had backed up on a USB. This sits at 120bpm with a Chillstep drop towards the end. If you can wait until the drop hits, I'm 99% sure you'll feel something.")
      expect(attributes.artist).to eq("swami~harami")

      expect(attributes.valid?).to eq(true)
    end
  end

  context "when artwork is not present but track is present" do
    it 'should get properties from facebook and soundcloud attributes' do
      fixture = JSON.parse(File.read(Settings.root_path.join('spec/integrations/soundcloud/fixtures/example4.json')))

      attributes = Aggregator::Providers::Soundcloud::Attributes.new(fixture)
      expect(attributes.name).to eq("Diyar E Dil OST Hum TV")
      expect(attributes.link).to eq("http://soundcloud.com/goharali-1/sets/yaar-e-mann")
      expect(attributes.picture).to eq("https://i1.sndcdn.com/artworks-000116618161-ruvydy-t500x500.jpg")
      expect(attributes.description).to eq("Finished this three months ago, one of the project's I had backed up on a USB. This sits at 120bpm with a Chillstep drop towards the end. If you can wait until the drop hits, I'm 99% sure you'll feel something.")
      expect(attributes.artist).to eq("madeeha gauhar")
    end
  end
end
