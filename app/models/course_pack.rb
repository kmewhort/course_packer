require 'pdf_utils'
require 'swf_utils'
require 'carrierwave'

class CoursePack
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  mount_uploader :title_page, DocUploader
  mount_uploader :toc, DocUploader
  mount_uploader :preview, UnprocessedFileUploader
  field :preview_generated_at, type: Time

  has_many :articles, order: 'weight ASC'
  accepts_nested_attributes_for :articles, allow_destroy: true

  attr_accessible :articles_attributes, :title, :title_page, :toc, :preview

  after_save :generate_title_page #TODO if title, course, or professor are updates
  after_save :generate_toc #TOOD if articles changed

  def generate_preview
    return false unless articles.any?{|a| !a.file.swf.path.nil? }

    # get the page-trimmed articles
    article_swfs = articles.map do |a|
      if a.file.swf.path.nil?
        nil
      elsif !a.trimmed?
        a.file.swf
      else
        a.trimmed_swf
      end
    end.compact

    # merge the article swf's together
    outfile = Tempfile.new(["#{id}-preview",".swf"])
    SwfUtils::merge(article_swfs.map(&:path), outfile.path)
    raise "Error merging files" if outfile.length == 0

    self.preview = CarrierWave::SanitizedFile.new(outfile)
    self.preview_generated_at = Time.now
    save!
  end

  def preview_up_to_date?
    !preview_generated_at.nil? && # preview has been generated
    updated_at.to_time.to_i <= preview_generated_at.to_time.to_i && # course pack changes are older than preview
    articles.all?{|a| a.updated_at.to_time.to_i <= preview_generated_at.to_time.to_i } # article changes are older
  end

  # number of pages overall (all articles, plus toc, but not the title page)
  def number_of_pages
    pages = articles.map{|a| a.num_pages}.reduce(0,:+)
    unless toc.path.nil?
      pages += PdfUtils::count_pages(toc.path)
    end
    pages
  end

  # error messages w/ full details for nested articles
  def error_messages
    errors = self.errors.full_messages
    if errors.delete 'Articles is invalid'
      self.articles.each do |a|
        errors += a.errors.messages.values
      end
    end
    errors
  end

  def as_json(options={})
    result = super(options)
    result[:articles] = articles.map{|a| a.as_json(options)}
    result
  end

  private
  def generate_title_page
    #TODO
  end

  def generate_toc
    #TODO
  end
end