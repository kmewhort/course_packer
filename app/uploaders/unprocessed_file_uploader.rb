class UnprocessedFileUploader < CarrierWave::Uploader::Base
  storage :file

  # include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  include Sprockets::Helpers::RailsHelper
  include Sprockets::Helpers::IsolatedHelper

  # directory where uploaded files will be stored
  def store_dir
    "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # white list of extensions which are allowed to be uploaded.
#  def extension_white_list
#    %w(doc docx odt rdf txt pdf)
#  end
end
