# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kolors/version'

Gem::Specification.new do |gem|
  gem.name          = "kolors"
  gem.version       = Kolors::VERSION
  gem.authors       = ["Eric Larson"]
  gem.email         = ["ewlarson@gmail.com"]
  gem.description   = %q{Uses KMeans clustering and the L*A*B* colorspace to extract "approximate human vision" dominant colors from an image. Optionally, use Euclidean Distance to map those dominant colors into preferred "color bins" for a search index facet-by-color solution.}
  gem.summary       = %q{Uses KMeans clustering and the L*A*B* colorspace to extract "approximate human vision" dominant colors from an image.}
  gem.homepage      = "https://github.com/ewlarson/kolors"
  
  gem.requirements  = 'ImageMagick'
  gem.add_dependency 'ai4r'
  gem.add_dependency 'cocaine'
  gem.add_dependency 'oily_png'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
