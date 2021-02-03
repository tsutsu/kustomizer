# frozen_string_literal: true

require_relative "lib/kustomize/version"

Gem::Specification.new do |spec|
  spec.name          = "kustomizer"
  spec.version       = Kustomize::VERSION
  spec.authors       = ["Levi Aul"]
  spec.email         = ["levi@leviaul.com"]

  spec.summary       = "Pure-ruby impl of Kubernetes kustomize"
  spec.description   = "A pure-ruby implementation of the Kubernetes 'kustomize' command."
  spec.homepage      = "https://github.com/tsutsu/kustomize"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "accessory", "~> 0.1.11"
  spec.add_runtime_dependency "base32-multi"
end
