require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe Kolors::DominantColors do
  before(:each) do
    @kolors = Kolors::DominantColors.new('../../fixtures/red_tetrad.png')
  end
  
  it "should properly cluster a red tetrad" do
    @kolors.to_lab.should match_array([[50.861, -24.406, -8.025], [59.711, 48.424, 61.115], [53.233, 80.109, 67.22], [66.882, -55.641, 61.082]])
  end
end