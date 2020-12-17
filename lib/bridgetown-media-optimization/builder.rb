# frozen_string_literal: true

require "pry"
require "image_processing/mini_magick"
require "image_processing/vips"

module BridgetownMediaOptimization
  class Builder < Bridgetown::Builder
    attr_reader :attributes
    attr_reader :media_optimizations

    def build
      @media_optimizations ||= {}

      liquid_tag "resp_picture", as_block: true do |attributes, tag|
        @attributes = attributes.split(",").map(&:strip)
        path = tag.context["src"]
        path ||= @attributes.first
        # transformation_specs = JSON.parse(attributes.split(",").map(&:strip).last)
        lazy = kargs.fetch("lazy") { false }
        transformation_specs = kargs.fetch("transformation_specs") {
          {
            # scaled width, srcset_descriptor
            "webp" => [[640, "640w"], [1024, "1024w"], [1280, "1280w"], [1920, "1920w"], [3840, "2x"]],
            "jpg" => [[640, "640w"], [1024, "1024w"], [1280, "1280w"], [1920, "1920w"], [3840, "2x"]]
          }
        }
        @media_optimizations.merge!({path => transformation_specs})
        picture_tag(path: path, lazy: lazy, attributes: tag.content, transformation_specs: transformation_specs)
      end

      hook :site, :post_write do |site|
        # kick off transformations
        media_optimizations.each do |path, spec|
          next if path.empty?

          pipeline = ImageProcessing::Vips.source(File.join(site.source, path))

          spec.each do |format, specs|
            pipeline.convert(format) 

            # pipeline.saver(interlace: true) if format == "jpg"

            specs.each do |spec|
              destination = File.join(site.config["destination"], "#{File.join(File.dirname(path), file_basename(path))}-#{spec.first}.#{format}")

              unless File.exist? destination
                Bridgetown.logger.debug "Generating #{destination}"

                pipeline
                  .resize_to_limit(spec.first, spec.first)
                  .call(destination: destination)
              end
            end
          end
        end
      end
    end

    def picture_tag(path: "", lazy: false, attributes:, transformation_specs:)
      source_elements = transformation_specs.map do |format, spec|
        srcset = spec.map do |s|
          scaled_width, srcset_descriptor = s
          "#{File.join(File.dirname(path), file_basename(path))}-#{scaled_width}.#{format} #{srcset_descriptor}"
        end.join(", ")
        "<source #{lazy ? 'data-' : ''}srcset=\"#{srcset}\" type=\"image/#{format}\"></source>"
      end

      tag = <<~PICTURE
        <picture>
          #{source_elements.join("\n")}
          <img #{lazy ? 'data-' : ''}src="#{path}" #{attributes}>
        </picture>
      PICTURE
      tag
    end
    
    private

    def kargs
      return {} unless attributes.size > 1
      
      json_payload = attributes[1..].join(", ")
      @kargs = JSON.parse(JSON.parse(json_payload).gsub("'", "\""))
    end

    def file_basename(path)
      File.basename(File.join(site.source, path), ".*")
    end
  end
end

BridgetownMediaOptimization::Builder.register
