# Bridgetown Media Transformation

A Bridgetown plugin to [fill in the blank]…

## Installation

Run this command to add this plugin to your site's Gemfile:

```shell
$ bundle add bridgetown-media-transformation -g bridgetown_plugins
```

### with VIPS

### with ImageMagick

## Usage

The plugin will…

### Optional configuration options

```yaml
# bridgetown.config.yml

media_transformation:
  # Whether to optimize transformed images with image_optim
  #
  # Type: Boolean
  # Optional: true
  # Default: false
  optimize: true

  # Whether to progressive scan JPGs
  #
  # Type: Boolean
  # Optional: true
  # Default: false
  interlace: true

  # The default transformations
  #
  # Type: Hash
  # Optional: true
  # Default:
  #   {
  #     "webp" => [[640, "640w"], [1024, "1024w"], [1280, "1280w"], [1920, "1920w"], [3840, "2x"]],
  #     "jpg" => [[640, "640w"], [1024, "1024w"], [1280, "1280w"], [1920, "1920w"], [3840, "2x"]]
  #   }
  default_transformations:
    webp:
      -
        - 320
        - 320w
      -
        - 2000
        - 2000w
    jpg:
      -
        - 320
        - 320w
      -
        - 2000
        - 2000w
```
…

## Testing

* Run `BRIDGETOWN_ENV=test script/test` to run the test suite
* Or run `BRIDGETOWN_ENV=test script/cibuild` to validate with Rubocop and test with rspec together.

## Contributing

1. Fork it (https://github.com/username/my-awesome-plugin/fork)
2. Clone the fork using `git clone` to your local development machine.
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request

