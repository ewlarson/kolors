require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe Kolors::DominantColors do
  before(:each) do
    @kolors = Kolors::DominantColors.new(file_path('red_tetrad.png'))
    @red_tetrad = [{"Teal"=>25.0}, {"Tangerine"=>25.0}, {"Maraschino"=>25.0}, {"Clover"=>25.0}] 
  end
  
  # KMeans clustering
  it "should properly cluster a red tetrad to LAB colorspace" do
    @kolors.to_lab.should match_array([[50.861, -24.406, -8.025], [59.711, 48.424, 61.115], [53.233, 80.109, 67.22], [66.882, -55.641, 61.082]])
  end
  
  # KMeans-based facet colors
  it "should build the correct facets" do
    # Color => Percentage
    @kolors.to_facets.each do |facet|
      @red_tetrad.should include(facet)
    end
  end
  
  # Pixel-count-based facet colors
  it "should properly color bin the pixel counts" do
    # Color => Pixel Count Percentage
    @kolors.color_bins_result.each do |facet|
      @red_tetrad.should include(facet)
    end
  end
  
end