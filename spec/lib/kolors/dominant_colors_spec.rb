require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe Kolors::DominantColors do
  before(:each) do
    @kolors = Kolors::DominantColors.new(file_path('red_tetrad.png'))
    @red_tetrad = [{"Teal"=>25.0}, {"Tangerine"=>25.0}, {"Maraschino"=>25.0}, {"Clover"=>25.0}] 
  end
  
  # Pixel-count-based facet colors
  it "should properly color bin the pixel counts" do
    # Color => Pixel Count Percentage
    @kolors.color_bins_result.each do |facet|
      @red_tetrad.should include(facet)
    end
  end
  
end