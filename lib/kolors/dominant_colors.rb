module Kolors
  class DominantColors
    attr_accessor :src_image_path
    
    def initialize(src_image_path)
      @src_image_path = src_image_path
    end

    def to_facets
      # Map each centroid to key_colors
      facets = to_lab.each_with_index.collect do |color,index| 
        { key_colors[key_colors.keys.sort_by {|c| dist(color, c) }.first] => kmeans_result.clusters[index].data_items.size}
      end
      percentize(group_hashes_sum_values(facets))
    end
    
    def to_rgb
      kmeans_result.centroids
    end  
    
    def to_lab
      kmeans_result.centroids.collect{|r,g,b| Kolors::Rgb.new(r,g,b).to_lab}
    end
    
    def kmeans_result
      @kmeans_result ||= extract_colors_from_image
    end
    
    def color_bins_result
      @color_bin_counts_result ||= extract_color_bin_percentages_from_image
    end
    
    private
    
    def percentize(hash)
      hash.collect{|color, count| {color => ((count.to_f / @colors.size.to_f)*100)}}
    end
    
    def group_hashes_sum_values(array)
      array.inject{|color, count| color.merge( count ){|k, old_v, new_v| old_v + new_v}}
    end

    def extract_colors_from_image
      create_thumb_crop_and_convert_to_png!
      colors = detect_dominant_colors
      cleanup_temporary_files!
      return colors
    end
    
    def extract_color_bin_percentages_from_image
      create_thumb_crop_and_convert_to_png!
      colors = detect_color_bin_percentages
      cleanup_temporary_files!
      return colors
    end

    def remote_source_image?
      @src_image_path =~ /^https?:\/\//
    end

    def create_thumb_crop_and_convert_to_png!
      @source_image = open_source_image
      @downsampled_image = open_downsampled_image

      Cocaine::CommandLine.new(Kolors.options[:image_magick_path], "':in[0]' -resize :resolution -gravity Center -crop 90x80%+0+0 :out").
        run(:in => File.expand_path(@source_image.path),
            :resolution => Kolors.options[:resolution],
            :out => File.expand_path(@downsampled_image.path))
    end

    def open_source_image
      if remote_source_image?
        original_extension = URI.parse(@src_image_path).path.split('.').last

        tempfile = Tempfile.open(["source", ".#{original_extension}"])
        remote_file_data = open(@src_image_path).read

        tempfile.write(RUBY_VERSION =~ /1.9/ ? remote_file_data.force_encoding("UTF-8") : remote_file_data)
        tempfile.close
        return tempfile
      else
        return File.open(@src_image_path)
      end
    end

    def open_downsampled_image
      tempfile = Tempfile.open(["downsampled", '.png'])
      tempfile.binmode
      tempfile
    end
    
    def collect_pixels
      @colors ||= ChunkyPNG::Image.from_file(File.expand_path(@downsampled_image.path)).pixels.collect {|c| ChunkyPNG::Color.to_truecolor_bytes c }
    end

    def detect_dominant_colors
      # Detect dominant colors
      # Kmeans cluster
      data = Ai4r::Data::DataSet.new(:data_items => collect_pixels)
      kmeans = Ai4r::Clusterers::KMeans.new
      result = kmeans.build(data, Kolors.options[:color_count])
    end
    
    def detect_color_bin_percentages
      color_bins = Array.new
      collect_pixels.collect{|r,g,b| Kolors::Rgb.new(r,g,b).to_lab}.each do |color|
        color_bins << {key_colors[key_colors.keys.sort_by {|c| dist(color, c) }.first] => 1}
      end
      
      percentize(group_hashes_sum_values(color_bins))
    end

    def cleanup_temporary_files!
      @source_image.close(true) if remote_source_image?
      @downsampled_image.close(true)
    end
  end
end