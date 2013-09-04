require 'libreconv'

module CarrierWave
  module Libreconv
    extend ActiveSupport::Concern

    module ClassMethods
      def convert_to_pdf
        process :convert_to_pdf
      end
    end

    def convert_to_pdf
      return if File.extname(current_path) == '.pdf' # already a pdf file

      # convert to PDF
      target_file_path = File.join(File.dirname(current_path), File.basename(current_path, ".*") + '.pdf')
      ::Libreconv.convert(current_path, target_file_path)

      # move the PDF to the location of current_path
      File.delete(current_path)
      File.rename(target_file_path, current_path)
    end
  end
end