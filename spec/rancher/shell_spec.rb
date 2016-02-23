require 'spec_helper'

describe Rancher::Shell do
  it 'has a version number' do
    expect(Rancher::Shell::VERSION).not_to be nil
  end
end
