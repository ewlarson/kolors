module Kolors
  class Rgb
    attr_reader :r, :g, :b
    attr_reader :l, :a, :b
  
    def initialize(r,g,b)
      @r = r
      @g = g
      @b = b
    end
  
    # EasyRGB - RGB to LAB
    # - LAB gives us a perceptually accurate colorspace
    def to_lab
      x,y,z = rgb_to_xyz(@r,@g,@b)
      l,a,b = xyz_to_lab(x,y,z)
    end
  
    protected
  
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
  end
end