require "codeclimate-test-reporter"

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  CodeClimate::TestReporter::Formatter,
  SimpleCov::Formatter::HTMLFormatter,
])
SimpleCov.start do
  add_filter "spec"
end
