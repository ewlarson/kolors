#!/Users/ewlarson/.rvm/rubies/ruby-1.9.3-p327/bin/ruby

require 'rubygems'
require 'mechanize'   # Crawl UW Digital Collection for data, images
require 'chunky_png'  # Pure Ruby image manipulation
require 'miro'        # Detect dominant image colors
require 'rsolr'       # Solr
require 'fileutils'   # Save files
require 'awesome_print'
require 'active_support/core_ext/string'

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

# Miro options
Miro.options[:image_magick_path] = '/usr/local/bin/convert'
Miro.options[:resolution] = '100x100'
Miro.options[:color_count] = 4

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

  { [128,0,0] => 'Cayenne', [128,128,0] => 'Asparagus', [0,128,0] => 'Clover', [0,128,128] => 'Teal', [0,0,128] => 'Midnight', [128,0,128] => 'Plum', [128,64,0] => 'Mocha', [64,128,0] => 'Fern', [0,128,64] => 'Moss', [0,64,128] => 'Ocean', [64,0,128] => 'Eggplant', [128,0,64] => 'Maroon', [255,0,0] => 'Maraschino', [255,255,0] => 'Lemon', [0,255,0] => 'Spring', [0,255,255] => 'Turquoise', [0,0,255] => 'Blueberry', [255,0,255] => 'Magenta', [255,128,0] => 'Tangerine', [128,255,0] => 'Lime', [0,255,128] => 'Sea Foam', [0,128,255] => 'Aqua', [128,0,255] => 'Grape', [255,0,128] => 'Strawberry', [255,102,102] => 'Salmon', [255,255,102] => 'Banana', [102,255,102] => 'Flora', [102,255,255] => 'Ice', [102,102,255] => 'Orchid', [255,102,255] => 'Bubblegum', [25,25,25] => 'Lead', [230,230,230] => 'Mercury', [255,204,102] => 'Cantaloupe', [204,255,102] => 'Honeydew', [102,255,204] => 'Spindrift', [102,204,255] => 'Sky', [204,102,255] => 'Lavender', [255,111,207] => "Carnation", [0,0,0] => "Licorice", [255,255,255] => 'Snow' }
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
  # Miro + ImageMagick
  # Using thumbnails is critical to reducing "noise" within the colors

  # Miro inspired conversion jpg to png
  Cocaine::CommandLine.new(Miro.options[:image_magick_path], "':in[0]' :out").
    run(
      :in => File.expand_path("#{identifier}_thumb.jpg"),
      :out => File.expand_path("#{identifier}_thumb.png")
    )
  
  # ChunkyPNG for cropping
  img = ChunkyPNG::Image.from_file("#{identifier}_thumb.png")
  point_of_interest = center_point(img)
  img.crop_square_at_center_point(point_of_interest[0], point_of_interest[1], 90).save("#{identifier}_cropped.png")

  # Detect dominant colors
  colors = Miro::DominantColors.new("#{identifier}_cropped.png")
  
  # Map each dominant color to img_key_colors
  img_key_colors = colors.to_rgb.collect{|color| key_colors[key_colors.keys.sort_by {|c| dist(color, c) }.first]}
  
  puts "Colors: #{img_key_colors.uniq.inspect}"

  # Build 
  # - Array of Colors Facet values (ex. ["Cayenne", "Asparagus", etc.])
  # - Color Percentage values (ex. "Cayenne" => 68.123)
  metadata["colors_ss"] = Array.new
  color_percentages = colors.by_percentage
  img_key_colors.each_with_index do |color, i|
    metadata['colors_ss'] << color unless metadata['colors_ss'].include?(color)
    metadata["#{color}_f"] = color_percentages[i] * 100
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