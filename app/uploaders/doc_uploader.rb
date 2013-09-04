require 'carrierwave_libreconv'
require 'carrierwave_swf'
require 'carrierwave_mupdf'

# uploader for article documents
class DocUploader < CarrierWave::Uploader::Base
  storage :file

  # processors
  include CarrierWave::RMagick
  # include CarrierWave::MiniMagick
  include CarrierWave::Libreconv
  include CarrierWave::Swf
  include CarrierWave::MuPdf

  # include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  include Sprockets::Helpers::RailsHelper
  include Sprockets::Helpers::IsolatedHelper

  # directory where uploaded files will be stored
  def store_dir
    "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # white list of extensions which are allowed to be uploaded.
  def extension_white_list
    %w(doc docx odt rdf txt pdf)
  end

  version :pdf do
    process :convert_to_pdf
  end

  version :swf, :from_version => :pdf do
    process :convert_to_swf
  end

  version :first_page, :from_version => :pdf do
    process :convert_to_png => [{ pages: '1' }]
  end

  version :thumbnail, :from_version => :first_page do
    process :resize_to_fit => [150,150]
  end
end
