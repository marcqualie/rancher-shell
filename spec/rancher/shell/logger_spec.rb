require "logger"
require "rancher/shell/logger"

describe Rancher::Shell::Logger do
  it "inherits from Logger" do
    expect(Rancher::Shell::Logger.ancestors).to include(Logger)
  end
end
