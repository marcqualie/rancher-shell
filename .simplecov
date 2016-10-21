require "codeclimate-test-reporter"
require 'codecov'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  CodeClimate::TestReporter::Formatter,
  SimpleCov::Formatter::Codecov,
  SimpleCov::Formatter::HTMLFormatter,
])
SimpleCov.start do
  add_filter "spec"
end
