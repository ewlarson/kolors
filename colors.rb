#!/Users/ewlarson/.rvm/rubies/ruby-1.9.3-p327/bin/ruby

# @TODO
# 1) Extract color conversion
# 2) Solr connection doesn't belong here
# 3) Imagemagick path should be configurable
# 4) Key colors should be configurable
# 5) All metadata should be isolated


require 'rubygems'
require 'mechanize'   # Crawl UW Digital Collection for data, images
require 'chunky_png'  # Pure Ruby image manipulation
require 'ai4r'        # Kmeans
require 'rsolr'       # Solr
require 'fileutils'   # Save files
require 'awesome_print'
require 'active_support/core_ext/string'
require 'cocaine'

module ChunkyPNG::Canvas::Operations
  def crop_square_at_center_point(x,y,size)
    x = x - ( size / 2)
    x = 0 if x<0
    y = y - ( size / 2 )
    y = 0 if y<0
    self.crop(x,y,size,size)
  end
end

def center_point(image)
  [image.dimension.width/2, image.dimension.height/2]
end

# Configure for Solr
# - Using the default apache-solr-4.0.0/example/solr/collection1/conf/ schema.xml solrconfig.xml
# - Metadata will all use Solr's DynamicField syntax 
$solr = RSolr.connect :url => 'http://localhost:8983/solr/collection1'

# Site - UW-Madison Library Catalog
$host = 'http://search.library.wisconsin.edu'

# Define a list of key RGB colors
def key_colors
  
  # Color 
  # Removed - pulled too dark
  #[127,127,127]   =>  "Tin",
  #[128,128,128]   =>  "Nickel",
  #[102,102,102]   =>  "Steel",
  #[153,153,153]   =>  "Aluminum",
  #[76,76,76]      =>  "Iron",
  #[179,179,179]   =>  "Magnesium",
  #[51,51,51]      =>  "Tungsten",
  #[204,204,204]   =>  "Silver",

  { [25.531, 48.055, 38.060] => 'Cayenne', [51.868, -12.931, 56.677] => 'Asparagus', [46.229, -51.700, 49.898] => 'Clover', [48.256, -28.842, -8.481] => 'Teal', [12.975, 47.508, -64.704] => 'Midnight', [29.782, 58.940, -36.498] => 'Plum', [34.510, 23.976, 44.820] => 'Mocha', [47.660, -39.672, 51.639] => 'Fern', [46.722, -45.498, 26.354] => 'Moss', [27.367, 9.122, -41.018] => 'Ocean', [18.577, 50.163, -55.230] => 'Eggplant', [26.619, 50.976, 0.503] => 'Maroon', [53.233, 80.109, 67.220] => 'Maraschino', [97.138, -21.556, 94.482] => 'Lemon', [87.737, -86.185, 83.181] => 'Spring', [91.117, -48.080, -14.138] => 'Turquoise', [32.303, 79.197, -107.864] => 'Blueberry', [60.320, 98.254, -60.843] => 'Magenta', [67.050, 42.832, 74.026] => 'Tangerine', [89.910, -67.789, 85.826] => 'Lime', [88.485, -76.749, 46.572] => 'Sea Foam', [54.719, 18.790, -70.925] => 'Aqua', [40.911, 83.182, -93.300] => 'Grape', [54.885, 84.552, 4.066] => 'Strawberry', [63.112, 58.245, 30.548] => 'Salmon', [97.527, -18.441, 70.899] => 'Banana', [89.535, -69.168, 59.807] => 'Flora', [92.382, -39.947, -12.114] => 'Ice', [51.322, 43.621, -76.298] => 'Orchid', [68.008, 76.237, -48.630] => 'Bubblegum', [8.757, 0.001, -0.002] => 'Lead', [91.293, 0.005, -0.010] => 'Mercury', [84.692, 7.020, 56.682] => 'Cantaloupe', [94.019, -38.132, 66.065] => 'Honeydew', [91.100, -52.338, 12.396] => 'Spindrift', [78.011, -15.169, -33.928] => 'Sky', [61.273, 64.277, -59.740] => 'Lavender', [67.377, 65.168, -23.019] => "Carnation", [0.000, 0.000, 0.000] => "Licorice", [100.000, 0.005, -0.010] => 'Snow' }
end

# EasyRGB - RGB to XYZ
def rgb_to_xyz(r,g,b)
  r = r * 1.0
  g = g * 1.0
  b = b * 1.0

  var_R = ( r / 255.0 )        #R from 0 to 255
  var_G = ( g / 255.0 )        #G from 0 to 255
  var_B = ( b / 255.0 )        #B from 0 to 255

  if ( var_R > 0.04045 ) 
    var_R = ( ( var_R + 0.055 ) / 1.055 ) ** 2.4
  else                   
    var_R = var_R / 12.92
  end
  
  if ( var_G > 0.04045 ) 
    var_G = ( ( var_G + 0.055 ) / 1.055 ) ** 2.4
  else
    var_G = var_G / 12.92
  end

  if ( var_B > 0.04045 )
    var_B = ( ( var_B + 0.055 ) / 1.055 ) ** 2.4
  else
    var_B = var_B / 12.92
  end

  var_R = var_R * 100
  var_G = var_G * 100
  var_B = var_B * 100

  # Observer. = 2°, Illuminant = D65
  x = var_R * 0.4124 + var_G * 0.3576 + var_B * 0.1805
  y = var_R * 0.2126 + var_G * 0.7152 + var_B * 0.0722
  z = var_R * 0.0193 + var_G * 0.1192 + var_B * 0.9505
  
  return [x,y,z]
end

# EasyRGB - XYZ to CIELAB
def xyz_to_lab(x,y,z)
  var_X = x / 95.047            #ref_X =  95.047   Observer= 2°, Illuminant= D65
  var_Y = y / 100.000           #ref_Y = 100.000
  var_Z = z / 108.883           #ref_Z = 108.883

  if ( var_X > 0.008856 ) 
    var_X = var_X ** ( 1.0/3.0 )
  else
    var_X = ( 7.787 * var_X ) + ( 16.0 / 116.0 )
  end
  
  if ( var_Y > 0.008856 ) 
    var_Y = var_Y ** ( 1.0/3.0 )
  else
    var_Y = ( 7.787 * var_Y ) + ( 16.0 / 116.0 )
  end
  
  if ( var_Z > 0.008856 )
    var_Z = var_Z ** ( 1.0/3.0 )
  else
    var_Z = ( 7.787 * var_Z ) + ( 16.0 / 116.0 )
  end

  l = ( 116.0 * var_Y ) - 16.0
  a = 500.0 * ( var_X - var_Y )
  b = 200.0 * ( var_Y - var_Z )

  return [l.round(3),a.round(3),b.round(3)]
end

# EasyRGB - RGB to LAB
# - LAB gives us a perceptually accurate colorspace
def rgb_to_lab(r,g,b)
  x,y,z = rgb_to_xyz(r,g,b)
  l,a,b = xyz_to_lab(x,y,z)
end

# Euclidean distance
# - Take a dominant color from an image, return nearest key color
def dist(p1, p2)
 (0...p1.length).map {|i| (p1[i]-p2[i])**2}.inject(0) {|sum, i| sum+i}**0.5
end

# 3) Build Solr Document - Solr dynamic field syntax
def save_metadata(identifier, metadata)
  metadata['id'] = identifier
  $solr.add metadata
end

# Parse the identifier
def identifier(img_url)
  identifier = img_url.split('1711.dl:')[1].split('/')[0]
end

# Clean and map HTML table data to proper Solr dynamic fields
def sanitize_table_key(key)
  key = key.gsub('\n', ' ').gsub('/', ' ').titleize.gsub(' ', '').tableize
  
  key = case key
  when 'subjects'
    key + '_ss'
  when 'from_the_collection'
    key + '_ss'
  when 'type'
    key + '_ss'
  else
    key + '_t'
  end
end

def sanitize_subject_value(value)
  value.gsub('\n', '').split('--').join(', ').split('/').join(', ').split(', ').uniq
end

def sanitize_table_value(value)
  value.gsub('\n', '').strip
end

def save_details(identifier)
  # New Agent - Get Detail Page
  $agent.get("#{$host}/collections/PBO/items/#{identifier}").class
  
  # Metadata
  # - Scrape table for Solr document field values
  metadata = Hash.new
  $agent.page.search('table').search('tr').search('td.key').map{ |node|
    if sanitize_table_key(node.text) == 'subjects_ss'
      metadata[sanitize_table_key(node.text)] = sanitize_subject_value(node.next_element.text)
    else
      metadata[sanitize_table_key(node.text)] = sanitize_table_value(node.next_element.text)
    end
  }

  # Save thumb image color data
  # Using thumbnails is critical to reducing "noise" within the colors

  # Miro inspired conversion jpg to png
  Cocaine::CommandLine.new('/usr/local/bin/convert', "':in[0]' :out").
    run(
      :in => File.expand_path("#{identifier}_thumb.jpg"),
      :out => File.expand_path("#{identifier}_thumb.png")
    )
  
  # ChunkyPNG for cropping
  begin
    img = ChunkyPNG::Image.from_file("#{identifier}_thumb.png")
    point_of_interest = center_point(img)
    @image = img.crop_square_at_center_point(point_of_interest[0], point_of_interest[1], 90).save("#{identifier}_cropped.png")
  rescue
    return nil
  end

  # Detect dominant colors
  # - Fetches colors from ChunkyPNG directly
  colors = ChunkyPNG::Image.from_file(File.expand_path(@image.path)).pixels.collect {|c| ChunkyPNG::Color.to_truecolor_bytes c }
  colors_lab = colors.collect{|r,g,b| rgb_to_lab(r,g,b)}
  
  # Kmeans cluster
  data = Ai4r::Data::DataSet.new(:data_items => colors_lab)
  kmeans = Ai4r::Clusterers::KMeans.new
  result = kmeans.build(data, 4)

  # Map each color cluster to img_key_colors
  img_key_colors = result.centroids.collect{|color| key_colors[key_colors.keys.sort_by {|c| dist(color, c) }.first]}
  puts "Colors: #{img_key_colors.uniq.inspect}"

  # Build 
  # - Array of Colors Facet values (ex. ["Cayenne", "Asparagus", etc.])
  # - Color Percentage values (ex. "Cayenne" => 68.123)
  metadata["colors_ss"] = Array.new
  #color_percentages = colors.by_percentage
  img_key_colors.each_with_index do |color, i|
    metadata['colors_ss'] << color unless metadata['colors_ss'].include?(color)
    #metadata["#{color}_f"] = color_percentages[i] * 100
  end
  
  # Delete derivatives
  FileUtils.rm([File.expand_path("#{identifier}_cropped.png"), File.expand_path("#{identifier}_thumb.jpg")])

  # Save detail metadata
  save_metadata(identifier, metadata)
end

def save_results(images)
  FileUtils.cd('images', :verbose => true) do
    images.each do |img|
      result = $agent.get(img.url)
      
      begin
        identifier = identifier(img.url)
      rescue
        next
      end
      
      filename = identifier + '_thumb.jpg'
      if result.class == Mechanize::Image
        puts "- #{identifier}\n- THUMB "
        result.save(filename)
        save_details(identifier)
      else   
        puts "FAIL on #{img}"
      end
    end
  end  
end

# Recusive 
# 1) load search result spage
# 2) save thumbnail and metadata
# 3) commit to Solr
# X) Repeat
def load_results(page)
  save_results(page.images)
  $solr.commit
  
  page.links.each do |link|
    if link.text.include?('Next')
      sleep rand*3
      puts "Next: #{$host}#{link.href}"
      $agent.get($host + link.href).class
      load_results($agent.page)
    end
  end  
end

# New Agent
$agent = Mechanize.new
$agent.get("#{$host}/collections/PBO/items").class

# Load Page
load_results($agent.page)