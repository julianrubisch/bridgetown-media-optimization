# frozen_string_literal: true

require "image_processing/mini_magick"
require "image_processing/vips"
require "image_optim"
require "fileutils"

module BridgetownMediaTransformation
  class Builder < Bridgetown::Builder
    DEFAULT_TRANSFORMATION_SPECS = {
      "webp" => [[640, "640w"], [1024, "1024w"], [1280, "1280w"], [1920, "1920w"], [3840, "2x"]],
      "jpg" => [[640, "640w"], [1024, "1024w"], [1280, "1280w"], [1920, "1920w"], [3840, "2x"]]
    }

    attr_reader :attributes, :media_transformations

    def build
      @media_transformations ||= []

      Bridgetown.logger.info "[media-transformation] Interlacing JPEG: #{interlace?}"
      Bridgetown.logger.info "[media-transformation] Optimizing: #{optimize?}"

      liquid_tag "resp_picture", as_block: true do |attributes, tag|
        @attributes = attributes.split(",").map(&:strip)
        src = tag.context["src"]
        dest = tag.context["dest"]
        src ||= @attributes.first
        dest ||= src
        lazy = kargs.fetch("lazy") { false }
        transformation_specs = kargs.fetch("transformation_specs") { default_transformation_specs }

        transformation = MediaTransformation.new(dest: dest, src: src, specs: transformation_specs, optimize: optimize?, interlace: interlace?, site: site, builder: self)
        @media_transformations << transformation

        picture_tag(src: src, dest: dest, file_hash: transformation.file_hash, lazy: lazy, attributes: tag.content, transformation_specs: transformation_specs)
      end

      unless Bridgetown.environment == "test"
        hook :site, :post_write do |site|
          # kick off transformations
          media_transformations.each { |transformation| transformation.process }
        end
      end
    end

    def picture_tag(src: "", dest: "", file_hash:, lazy: false, attributes:, transformation_specs:)
      src_filename = "#{file_hash}-#{file_basename(src)}"
      prefixed_src = "#{File.join(File.dirname(dest), src_filename)}"

      source_elements = transformation_specs.map do |format, spec|
        srcset = spec.map do |s|
          scaled_width, srcset_descriptor = s
          "#{File.join(File.dirname(dest), file_basename(prefixed_src))}-#{scaled_width}.#{format} #{srcset_descriptor}"
        end.join(", ")
        "<source #{lazy ? 'data-' : ''}srcset=\"#{srcset}\" type=\"image/#{format}\" />"
      end

      tag = <<~PICTURE
        <picture>
          #{source_elements.join("\n")}
          <img #{lazy ? 'data-' : ''}src="#{src}" #{attributes}>
        </picture>
      PICTURE
      tag
    end

    def verbose?
      options.dig(:verbose) || Bridgetown.environment == "production"
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

    def interlace?
      options.dig(:interlace) || false
    end

    def optimize?
      options.dig(:optimize) || false
    end

    def options
      config["media_transformation"] || {}
    end

    def default_transformation_specs
      options.fetch(:default_transformations) { DEFAULT_TRANSFORMATION_SPECS }
    end
  end
end

BridgetownMediaTransformation::Builder.register
