$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "persisted_cache/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "persisted_cache"
  s.version     = PersistedCache::VERSION
  s.authors     = ["Bernd Ustorf"]
  s.email       = ["bernd@taxjar.com"]
  s.homepage    = "https://taxjar.com"
  s.summary     = "PersistedCache."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "> 4.2"

  s.add_development_dependency "sqlite3", "> 1.3"
  s.add_development_dependency "rspec-rails", "> 3.5"
end
