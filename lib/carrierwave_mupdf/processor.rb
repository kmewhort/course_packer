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

      # move the PNG file to the location of current_path
      File.delete(current_path)
      File.rename(target_file_path, current_path)
    end

    private
    def mupdf_default_options
      {
          pages: 1
      }
    end
  end
end