# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aggregator/version'

Gem::Specification.new do |spec|
  spec.name          = "aggregator"
  spec.version       = Aggregator::VERSION
  spec.authors       = ["Alexandr Korsak"]
  spec.email         = ["alex.korsak@gmail.com"]

  spec.summary       = %q{Library for recognizing the tracks from the different sources like youtube,shazam,grooveshark,mixlcoud,soundcloud,spotify}
  spec.description   = %q{Library for recognizing the tracks from the different sources like youtube,shazam,grooveshark,mixlcoud,soundcloud,spotify}
  spec.homepage      = "http://github.com/rubyforce/botmusic-aggregator/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sidekiq", "~> 4.0.1"
  # spec.add_dependency "airbrake", "~> 4.2.1"
  spec.add_dependency "koala", "~> 2.0.0"
  spec.add_dependency "rspotify", "~> 1.14.0"
  spec.add_dependency "yourub", "~> 2.0.2"
  spec.add_dependency "google-api-client", '0.8.6'
  spec.add_dependency "faraday", "~> 0.9.1"
  spec.add_dependency "simple-conf", "~> 0.3.1"
  spec.add_dependency "soundcloud", "~> 0.3.1"
  spec.add_dependency "naught", "~> 1.0.0"
  spec.add_dependency "yt", "~> 0.25.5"
  spec.add_dependency "le", "~> 2.6.2"
  # spec.add_dependency "facets", "~> 3.1.0"
  spec.add_dependency "nokogiri", "~> 1.6.7.rc3"
  spec.add_dependency "airbrake-ruby", "~> 1.2.1"

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
end
