require "codeclimate-test-reporter"

SimpleCov.start do
  add_filter "spec"
  add_group "Commands", "lib/rancher/shell/commands"
end
