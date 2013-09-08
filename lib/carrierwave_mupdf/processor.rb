module CarrierWave
  module MuPdf
    extend ActiveSupport::Concern

    module ClassMethods
      def convert_to_png(options = {})
        process :convert_to_png => options
      end
    end

    def convert_to_png(options = {})
      # convert with mupdf-tools
      target_file_path = File.join(File.dirname(current_path), File.basename(current_path, ".*") + '.png')
      options = mupdf_default_options.merge(options)
      `pdfdraw -o #{target_file_path} #{current_path} #{options[:pages]}`

      # resize the target file using rmagick or minimagick (whichever is included from the Uploader);
      # need to do this before moving the fie, as rMagick requires a correct file extension (and carrierwave
      # requires us to clobber the extension)
      unless options[:resize].nil?
        raise "Must include Rmagick or Minimagick in your uploader to resize the image" unless self.respond_to? :resize_to_fit

        orig_file = @file
        @file = File.open(target_file_path)
        resize_to_fit(options[:resize][0], options[:resize][1])
        @file = orig_file
      end

      # move the PNG file to the location of current_path
      File.delete(current_path)
      File.rename(target_file_path, current_path)
    end

    private
    def mupdf_default_options
      {
          pages: 1,
          resize: nil
      }
    end
  end
end