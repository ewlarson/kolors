module Kolors
  class DominantColors
    attr_accessor :src_image_path

    def initialize(src_image_path)
      @src_image_path = src_image_path
    end

    def to_facets
      # Map each centroid to key_colors
      percentize(group_hashes_sum_values(facets))
    end

    def to_rgb
      kmeans_result.centroids
    end  

    def to_lab
      to_rgb.map { |r,g,b| Kolors::Rgb.new(r,g,b).to_lab }
    end

    def kmeans_result
      @result ||= colors { detect_dominant_colors }
    end

    def color_bins_result
      colors { detect_color_bin_percentages }
    end

    def colors(&block)
      create_thumb_crop_and_convert_to_png!
      colors_found = yield if block_given?
      cleanup_temporary_files!
      colors_found
    end

    private

    def facets
      to_lab.each_with_index.map do |color,index| 
        key_color_names(color, index)
      end
    end

    def key_color_names(color, index)
      {KEY_COLORS[first_lab_value(color)] => cluster_size(index)}
    end

    def first_lab_value(color)
      KEY_COLORS.keys.sort_by {|c| dist(color, c) }.first
    end

    def cluster_size(index)
      kmeans_result.clusters[index].data_items.size
    end

    def percentize(hash)
      hash.map { |color, count| {color => color_precentage(count)} }.
        sort! { |a,b| b[b.keys.first] <=> a[a.keys.first] }
    end

    def color_precentage(count)
      (count.to_f / @colors.size.to_f)*100
    end

    def group_hashes_sum_values(array)
      array.inject { |color, count| color.
        merge(count) {|k, old_v, new_v| old_v + new_v} }
    end

    def remote_source_image?
      src_image_path =~ /^https?:\/\//
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
        original_extension = URI.parse(src_image_path).path.split('.').last

        tempfile = Tempfile.open(["source", ".#{original_extension}"])
        remote_file_data = open(src_image_path).read

        tempfile.write(RUBY_VERSION =~ /1.9/ ? remote_file_data.force_encoding("UTF-8") : remote_file_data)
        tempfile.close
        tempfile
      else
        File.open(src_image_path)
      end
    end

    def open_downsampled_image(tempfile=Tempfile)
      tempfile.open(["downsampled", '.png'])
    end

    def collect_pixels
      @colors ||= pixels.map { |pixel| truecolor(pixel) }
    end

    def truecolor(pixel)
      ChunkyPNG::Color.to_truecolor_bytes(pixel)
    end

    def downsampled_image_path
      File.expand_path(@downsampled_image.path)
    end

    def pixels
      ChunkyPNG::Image.from_file(downsampled_image_path).pixels
    end

    def detect_dominant_colors
      # Detect dominant colors
      # Kmeans cluster
      data = Ai4r::Data::DataSet.new(:data_items => collect_pixels)
      kmeans = Ai4r::Clusterers::KMeans.new
      result = kmeans.build(data, Kolors.options[:color_count])
    end

    def detect_color_bin_percentages
      bins =
        collect_pixels.map {|r,g,b| Kolors::Rgb.new(r,g,b).to_lab}.
        inject([]) { |color_bins, color| color_bins << {KEY_COLORS[KEY_COLORS.keys.
          sort_by {|c| dist(color, c) }.first] => 1} }

      percentize(group_hashes_sum_values(bins))
    end

    def cleanup_temporary_files!
      @source_image.close(true) if remote_source_image?
      @downsampled_image.close(true)
    end
  end
end
