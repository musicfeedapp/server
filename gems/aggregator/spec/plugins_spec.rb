require 'spec_helper'

describe Aggregator do
  Plugin1 = Struct.new(:param) do
    def perform
    end
  end

  it 'should be possible to register plugin' do
    Aggregator.register_plugin(:name1, Plugin1)
    expect(Aggregator.plugins(:name1)).to eq([Plugin1])
  end
end
