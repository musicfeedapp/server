require 'spec_helper'

describe TimelinesRecognize do
  it 'should skip in case of in unknow url' do
    timeline = TimelinesRecognize.do(url: "http://www.example.com/something")
    expect(timeline).to eq(nil)
  end

  it 'should skip youtube track in case of no music inside' do
    timeline = TimelinesRecognize.do(url: "https://www.youtube.com/watch?v=X6u1I3Prbnc")
    expect(timeline.valid?).to eq(false)
  end

  it 'should find youtube timeline by url' do
    timeline = TimelinesRecognize.do(url: "https://www.youtube.com/watch?v=Lo3U4n24DNA")
    expect(timeline.valid?).to eq(true)
  end

  it 'should find spotify timeline by url' do
    timeline = TimelinesRecognize.do(url: "http://open.spotify.com/track/1301WleyT98MSxVHPZCA6M")
    expect(timeline.valid?).to eq(true)
  end

  it 'should find spotify timeline by url' do
    timeline = TimelinesRecognize.do(url: "spotify:track:1301WleyT98MSxVHPZCA6M")
    expect(timeline.valid?).to eq(true)
  end

  it 'should skip find spotify timeline by url' do
    timeline = TimelinesRecognize.do(url: "spotify:track:something")
    expect(timeline.valid?).to eq(false)
  end

  it 'should find soundcloud timeline by url' do
    timeline = TimelinesRecognize.do(url: "https://soundcloud.com/justin-jet-zorbas/alex-nk-justin-jet-zorbas-beyond-the-horizon")
    expect(timeline.valid?).to eq(true)
  end

  it 'should skip find soundcloud timeline by url' do
    timeline = TimelinesRecognize.do(url: "https://soundcloud.com/unknown/link/goeshere")
    expect(timeline.valid?).to eq(false)
  end

  it 'should find shazam timeline by url' do
    timeline = TimelinesRecognize.do(url: "http://www.shazam.com/track/119138723/like-i-can")
    expect(timeline.valid?).to eq(true)
  end

  it 'should skip find shazam timeline by url' do
    timeline = TimelinesRecognize.do(url: "http://www.shazam.com/track/something/there")
    expect(timeline.valid?).to eq(false)
  end

  it 'should skip find shazam timeline by url' do
    timeline = TimelinesRecognize.do(artist: "Eminem", track: "Stan")
    expect(timeline.valid?).to eq(true)
  end
end
