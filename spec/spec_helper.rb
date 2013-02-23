require 'rubygems'
require 'bundler/setup'

require 'kolors' # and any other gems you need

def file_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', *paths))
end

RSpec.configure do |config|
  # some (optional) config here
end