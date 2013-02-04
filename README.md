# Kolors

Uses KMeans clustering and the L*A*B* colorspace to extract "approximate human vision" dominant colors from an image.  Optionally, map those dominant colors into preferred "color bins" for a search index facet-by-color solution.

LARGELY based off the neat work of the [Miro gem](https://github.com/jonbuda/miro).  If you want faster, RGB-based dominant color extraction, use Miro.

## Dependencies

Requires Imagemagick.  On OSX use homebrew to install: brew install imagemagick

## Installation

$ gem install kolors

## Usage

```ruby
require 'kolors'

# Use path to a local image or URL for remote image
kolors = Kolors::DominantColors.new('../colors/images/QFZMF57HPHVGJ8Z_thumb.png')

# Return the dominant colors in LAB
kolors.to_lab
 => [[52.406, -18.186, 27.618], [88.523, -10.393, 16.203], [64.944, -16.181, 24.419], [28.486, -16.665, 22.73]]

# Return the mapped color bins and color percentage for facet-by-color
kolors.to_facets
 => [{"Moss"=>50.05952380952381}, {"Mercury"=>9.880952380952381}, {"Aluminum"=>19.186507936507937}, {"Iron"=>20.873015873015873}]
```

## TODOS

1. LAB to RGB conversion
2. Simplify configuration of "color bins" for facet-by-color mapping
3. Tests

## Thanks

Special thanks to my buddy [Nate Vack](https://github.com/njvack) for help getting this off of the ground.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
