require 'spec_helper'

describe Cache do
  it 'should clear by pattern' do
    Cache.set("test:1:", 1)
    Cache.set("test:1:2", 2)
    Cache.set("test:3:3", 3)

    expect(Cache.get("test:1:")).to eq(1)
    expect(Cache.get("test:1:2")).to eq(2)
    expect(Cache.get("test:3:3")).to eq(3)

    Cache.clear('test:1')

    expect(Cache.get("test:1:")).to eq(nil)
    expect(Cache.get("test:1:2")).to eq(nil)
    expect(Cache.get("test:3:3")).to eq(3)
  end
end
