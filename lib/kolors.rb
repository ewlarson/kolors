require 'kolors/version'
require 'oily_png'        # Fast ChunkyPNG
require 'cocaine'
require 'open-uri'
require "tempfile"

require 'kolors/rgb'
require 'kolors/lab'
require 'kolors/dominant_colors'

# Define a list of key LAB colors
def key_colors
  # OSX Crayons in LAB 
  { [82.046, 0.004, -0.009] => 'Silver', [21.247, 0.002, -0.003] => 'Tungsten', [72.944, 0.004, -0.008] => 'Magnesium', [32.319, 0.002, -0.004] => 'Iron', [63.223, 0.004, -0.007] => 'Aluminum', [43.192, 0.003, -0.005] => 'Steel', [53.585, 0.003, -0.006] => 'Nickel', [53.193, 0.003, -0.006] => 'Tin', [25.531, 48.055, 38.060] => 'Cayenne', [51.868, -12.931, 56.677] => 'Asparagus', [46.229, -51.700, 49.898] => 'Clover', [48.256, -28.842, -8.481] => 'Teal', [12.975, 47.508, -64.704] => 'Midnight', [29.782, 58.940, -36.498] => 'Plum', [34.510, 23.976, 44.820] => 'Mocha', [47.660, -39.672, 51.639] => 'Fern', [46.722, -45.498, 26.354] => 'Moss', [27.367, 9.122, -41.018] => 'Ocean', [18.577, 50.163, -55.230] => 'Eggplant', [26.619, 50.976, 0.503] => 'Maroon', [53.233, 80.109, 67.220] => 'Maraschino', [97.138, -21.556, 94.482] => 'Lemon', [87.737, -86.185, 83.181] => 'Spring', [91.117, -48.080, -14.138] => 'Turquoise', [32.303, 79.197, -107.864] => 'Blueberry', [60.320, 98.254, -60.843] => 'Magenta', [67.050, 42.832, 74.026] => 'Tangerine', [89.910, -67.789, 85.826] => 'Lime', [88.485, -76.749, 46.572] => 'Sea Foam', [54.719, 18.790, -70.925] => 'Aqua', [40.911, 83.182, -93.300] => 'Grape', [54.885, 84.552, 4.066] => 'Strawberry', [63.112, 58.245, 30.548] => 'Salmon', [97.527, -18.441, 70.899] => 'Banana', [89.535, -69.168, 59.807] => 'Flora', [92.382, -39.947, -12.114] => 'Ice', [51.322, 43.621, -76.298] => 'Orchid', [68.008, 76.237, -48.630] => 'Bubblegum', [8.757, 0.001, -0.002] => 'Lead', [91.293, 0.005, -0.010] => 'Mercury', [84.692, 7.020, 56.682] => 'Cantaloupe', [94.019, -38.132, 66.065] => 'Honeydew', [91.100, -52.338, 12.396] => 'Spindrift', [78.011, -15.169, -33.928] => 'Sky', [61.273, 64.277, -59.740] => 'Lavender', [67.377, 65.168, -23.019] => "Carnation", [0.000, 0.000, 0.000] => "Licorice", [100.000, 0.005, -0.010] => 'Snow' }
  
  # Crayola Crayons - 16ct
  # { [0.0, 0.0, 0.0] => 'Black', [47.909, 35.209, -82.012] => 'Blue', [56.951, -21.113, -26.486] => 'Blue Green', [42.436, 30.554, -49.715] => 'Blue Violet', [47.76, 32.728, 31.38] => 'Brown', [77.727, 37.465, -4.165] => 'Pink', [59.159, -50.156, 20.795] => 'Green', [62.726, 54.468, 64.68] => 'Orange', [50.193, 76.218, 36.382] => 'Red', [57.137, 70.48, 50.904] => 'Red Orange', [45.117, 60.767, -14.844] => 'Red Violet', [45.101, 31.746, -33.512] => 'Violet (Purple)', [100.0, 0.005, -0.01] => 'White', [91.412, -8.107, 59.726] => 'Yellow', [85.567, -25.05, 47.104] => 'Yellow Green', [77.236, 20.651, 64.455] => 'Yellow Orange' }
end

# Euclidean distance
# - Take a dominant color from an image, return nearest key color
def dist(p1, p2)
 (0...p1.length).map {|i| (p1[i]-p2[i])**2}.inject(0) {|sum, i| sum+i}**0.5
end

module Kolors
  class << self
    def options
      @options ||= {
        :image_magick_path  => '/usr/local/bin/convert',
        :resolution         => '100x100',
        :color_count        => 4
      }
    end
  end
end