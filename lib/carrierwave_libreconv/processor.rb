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
      input_file_path = current_path
      target_file_path = File.join(File.dirname(current_path), File.basename(current_path, ".*") + '.pdf')

      # for HTML files, we get much better formatting with PDFkit
      if File.extname(current_path) == '.htm' || File.extname(current_path) == '.html'
        kit = PDFKit.new(File.new(input_file_path), :page_size => 'Letter')
        kit.to_file(target_file_path)
      # for everything else, use libreconv
      else
        ::Libreconv.convert(input_file_path, target_file_path)
      end

      # move the PDF to the location of current_path
      File.delete(current_path)
      File.rename(target_file_path, current_path)
    end
  end
end