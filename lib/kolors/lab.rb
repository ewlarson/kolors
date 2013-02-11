module Kolors
  class Lab
    attr_reader :r, :g, :b
    attr_reader :l, :a, :b
  
    def initialize(l,a,b)
      @l = l
      @a = a
      @b = b
    end
  
    # EasyRGB - LAB to RGB
    # - RGB gives us a cartoony colorspace
    def to_rgb
      x,y,z = lab_to_xyz(@l,@a,@b)
      r,g,b = xyz_to_rgb(x,y,z)
    end
    
    private

    def lab_to_xyz(l,a,b)
      var_Y = ( l + 16 ) / 116
      var_X = a / 500 + var_Y
      var_Z = var_Y - b / 200

      if ( var_Y**3 > 0.008856 ) 
        var_Y = var_Y**3
      else                      
        var_Y = ( var_Y - 16 / 116 ) / 7.787
      end
  
      if ( var_X**3 > 0.008856 ) 
        var_X = var_X**3
      else                      
        var_X = ( var_X - 16 / 116 ) / 7.787
      end
  
      if ( var_Z**3 > 0.008856 ) 
        var_Z = var_Z**3
      else
        var_Z = ( var_Z - 16 / 116 ) / 7.787
      end

      x = 95.047 * var_X      # ref_X =  95.047     Observer= 2°, Illuminant= D65
      y = 100.000 * var_Y     # ref_Y = 100.000
      z = 108.883 * var_Z     # ref_Z = 108.883
  
      return [x,y,z]
    end

    def xyz_to_rgb(x,y,z)
      var_X = x / 100        # X from 0 to  95.047      (Observer = 2°, Illuminant = D65)
      var_Y = y / 100        # Y from 0 to 100.000
      var_Z = z / 100        # Z from 0 to 108.883

      var_R = var_X *  3.2406 + var_Y * -1.5372 + var_Z * -0.4986
      var_G = var_X * -0.9689 + var_Y *  1.8758 + var_Z *  0.0415
      var_B = var_X *  0.0557 + var_Y * -0.2040 + var_Z *  1.0570

      if ( var_R > 0.0031308 ) 
        var_R = 1.055 * ( var_R ** ( 1 / 2.4 ) ) - 0.055
      else
        var_R = 12.92 * var_R
      end
  
      if ( var_G > 0.0031308 ) 
        var_G = 1.055 * ( var_G ** ( 1 / 2.4 ) ) - 0.055
      else
        var_G = 12.92 * var_G
      end
  
      if ( var_B > 0.0031308 ) 
        var_B = 1.055 * ( var_B ** ( 1 / 2.4 ) ) - 0.055
      else
        var_B = 12.92 * var_B
      end
  
      r = var_R * 255
      g = var_G * 255
      b = var_B * 255
  
      return [r,g,b]
    end
  end
end