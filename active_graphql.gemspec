
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_graphql/version"

Gem::Specification.new do |spec|
  spec.name          = "active_graphql"
  spec.version       = ActiveGraphql::VERSION
  spec.authors       = ["Povilas Jurcys"]
  spec.email         = ["po.jurcys@gmail.com"]

  spec.summary       = %q{Graphql client}
  spec.homepage      = "https://github.com/samesystem/active_graphql"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/samesystem/active_graphql"
    spec.metadata["changelog_uri"] = "https://github.com/samesystem/active_graphql/blob/v#{ActiveGraphql::VERSION}/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'graphlient', '~> 0.3'
  spec.add_dependency 'activesupport', '>= 4.0.0'
  spec.add_dependency 'activemodel', '>= 3.0.0'

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "webmock", "~> 3"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "0.75"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rspec"
end
