require 'ruby-prof'
require 'kolors'

result = RubyProf.profile do
  kolors = Kolors::DominantColors.new('spec/fixtures/red_tetrad.png')
  kolors.to_facets
end

printer = RubyProf::GraphPrinter.new(result)

File.open('kolors_profile.txt', 'w') do |file|
  printer.print(file)
end
