# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rancher/shell/version'

Gem::Specification.new do |spec|
  spec.name          = "rancher-shell"
  spec.version       = Rancher::Shell::VERSION
  spec.authors       = ["Marc Qualie"]
  spec.email         = ["marc@marcqualie.com"]

  spec.summary       = "A console utility for shelling into Rancher containers"
  spec.homepage      = "https://github.com/marcqualie/rancher-shell"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "websocket", "1.2.5"
  spec.add_dependency "event_emitter", "0.2.6"
  spec.add_dependency "thor", "~> 0.20"
  spec.add_dependency "activesupport", "~> 5.1"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 1.0"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "rspec", "~> 3.7"
end
