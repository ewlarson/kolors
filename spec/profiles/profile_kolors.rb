require 'ruby-prof'
require 'kolors'

result = RubyProf.profile do
  kolors = Kolors::DominantColors.new('spec/fixtures/red_tetrad.png')
  kolors.to_facets
end

printer = RubyProf::MultiPrinter.new(result)
printer.print(path: 'spec/profiles/kolors', profile: 'kolors')
