require 'pdf_utils'
require 'swf_utils'
require 'carrierwave'
require 'libreconv'

class CoursePack
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :author, type: String
  field :date, type: String, # string so the field can be used for terms, semesters, etc.
         default: Time.now.strftime("%B %Y")

  mount_uploader :title_page, DocUploader
  mount_uploader :toc, DocUploader
  mount_uploader :preview, UnprocessedFile
  field :preview_generated_at, type: Time

  has_many :contents, order: 'weight ASC'
  accepts_nested_attributes_for :contents, allow_destroy: true

  attr_accessible :contents_attributes, :title, :author, :date

  def generate_preview
    return false unless articles.any?{|a| !a.file.swf.path.nil? }

    # generate the TOC and title page (ERB->html->pdf->swf)
    generate_title_page
    generate_toc
    save!

    # get the page-trimmed articles
    article_swfs = articles.sort_by(&:weight).map do |a|
      if a.file.swf.path.nil?
        nil
      elsif !a.trimmed?
        a.file.swf
      else
        a.trimmed_swf
      end
    end.compact

    # merge the article swf's together
    merged = Tempfile.new(["#{id}-preview-merged",".swf"])
    SwfUtils::merge(([title_page.swf.path, toc.swf.path] + article_swfs.map(&:path)), merged.path)
    raise "Error merging files" if merged.length == 0

    # TO DO add page numbers
    #paged = Tempfile.new(["#{id}-preview-paged",".swf"])
    #SwfUtils::stamp_page_numbers(merged.path, number_of_pages, paged.path)
    #raise "Error adding page numbers files" if paged.length == 0

    self.preview = CarrierWave::SanitizedFile.new(merged)
    self.preview_generated_at = Time.now
    save!
  end

  def preview_up_to_date?
    !preview_generated_at.nil? && # preview has been generated
    updated_at.to_time.to_i <= preview_generated_at.to_time.to_i && # course pack changes are older than preview
    contents.all?{|a| a.updated_at.to_time.to_i <= preview_generated_at.to_time.to_i } # article changes are older
  end

  # number of pages overall (all articles, but not the title page or TOC)
  def number_of_pages
    articles.map{|a| a.num_pages_after_trimming}.reduce(0,:+)
  end

  # start page of a particular article
  def page_number_of(article)
    articles.sort_by(&:weight).reduce(1) do |sum,a|
      break(sum) if a == article
      sum + a.num_pages_after_trimming
    end
  end

  # error messages w/ full details for nested articles
  def error_messages
    errors = self.errors.full_messages
    if errors.delete 'Contents is invalid'
      self.contents.each do |a|
        errors += a.errors.messages.values
      end
    end
    errors
  end

  def articles
    contents.where(_type: 'Article')
  end

  def as_json(options={})
    result = super(options)
    result[:contents] = contents.map{|a| a.as_json(options)}
    result
  end

  private
  def generate_title_page
    html = ApplicationController.new.render_to_string(partial: 'pdf/title_page', locals: { course_pack: self } )

    html_file = Tempfile.new(["#{id}-title-page",".html"])
    html_file.write html
    html_file.close(false)

    self.title_page = CarrierWave::SanitizedFile.new(html_file)
  end

  def generate_toc
    html = ApplicationController.new.render_to_string(partial: 'pdf/toc', locals: { course_pack: self } )

    html_file = Tempfile.new(["#{id}-toc",".html"])
    html_file.write html
    html_file.close(false)

    self.toc = CarrierWave::SanitizedFile.new(html_file)
  end
end