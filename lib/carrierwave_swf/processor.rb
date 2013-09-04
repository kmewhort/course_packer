module CarrierWave
  module Swf
    extend ActiveSupport::Concern

    module ClassMethods
      def convert_to_swf(options = nil)
        process :convert_to_swf => options
      end
    end

    def convert_to_swf(options = nil)
      # convert with Swftools
      target_file_path = File.join(File.dirname(current_path), File.basename(current_path, ".*") + '.swf')
      options = swf_default_options if options.nil?
      `pdf2swf #{current_path} -o #{target_file_path} #{options}`

      # move the SWF file to the location of current_path
      File.delete(current_path)
      File.rename(target_file_path, current_path)
    end

    private
    def swf_default_options
      '-f -T 9 -t -s storeallcharacters'
    end
  end
end