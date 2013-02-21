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
    
    def rgb_standardize(var)
      if ( var > 0.04045 )
        var = ( ( var + 0.055 ) / 1.055 ) ** 2.4
      else
        var = var / 12.92
      end
      var * 100
    end
  
    # EasyRGB - RGB to XYZ
    def rgb_to_xyz(r,g,b)
      r = r * 1.0
      g = g * 1.0
      b = b * 1.0

      var_R = ( r / 255.0 )        #R from 0 to 255
      var_G = ( g / 255.0 )        #G from 0 to 255
      var_B = ( b / 255.0 )        #B from 0 to 255
      
      var_R = rgb_standardize(var_R)
      var_G = rgb_standardize(var_G)
      var_B = rgb_standardize(var_B)

      # Observer. = 2°, Illuminant = D65
      x = var_R * 0.4124 + var_G * 0.3576 + var_B * 0.1805
      y = var_R * 0.2126 + var_G * 0.7152 + var_B * 0.0722
      z = var_R * 0.0193 + var_G * 0.1192 + var_B * 0.9505
  
      return [x,y,z]
    end
    
    def xyz_standardize(var)
      if ( var > 0.008856 ) 
        var = var ** ( 1.0/3.0 )
      else
        var = ( 7.787 * var ) + ( 16.0 / 116.0 )
      end
    end
    
    # EasyRGB - XYZ to CIELAB
    def xyz_to_lab(x,y,z)
      var_X = x / 95.047            # ref_X =  95.047   Observer= 2°, Illuminant= D65
      var_Y = y / 100.000           # ref_Y = 100.000
      var_Z = z / 108.883           # ref_Z = 108.883
      
      var_X = xyz_standardize(var_X)
      var_Y = xyz_standardize(var_Y)
      var_Z = xyz_standardize(var_Z)

      l = ( 116.0 * var_Y ) - 16.0
      a = 500.0 * ( var_X - var_Y )
      b = 200.0 * ( var_Y - var_Z )

      return [l.round(3),a.round(3),b.round(3)]
    end
  end
end