require 'pdf_utils'
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
    return false unless articles.any?{|a| !a.file.pdf.path.nil? }

    # generate the TOC and title page (ERB->html->pdf)
    generate_title_page
    generate_toc
    save!

    self.preview = CarrierWave::SanitizedFile.new(self.print(:normal))
    self.preview_generated_at = Time.now
    save!
  end

  def print(type)
    # TODO: support for different print types

    # get the page-trimmed articles
    article_pdfs = articles.sort_by(&:weight).map do |a|
      if a.file.pdf.path.nil?
        nil
      else
        a.prepared_pdf
      end
    end.compact

    # merge the article pdf's together
    merged_articles = Tempfile.new(["#{id}-preview-merged",".pdf"])
    PdfUtils::merge(article_pdfs.map(&:path), merged_articles.path)
    raise "Error merging files" if merged_articles.length == 0

    # add page numbers
    paged = Tempfile.new(["#{id}-preview-paged",".pdf"])
    PdfUtils::stamp_page_numbers(merged_articles.path, paged.path, number_of_pages)
    raise "Error adding page numbers files" if paged.length == 0

    # add the title page and toc
    merged = Tempfile.new(["#{id}-preview-final",".pdf"])
    PdfUtils::merge([title_page.pdf.path, toc.pdf.path, paged.path], merged.path)
    raise "Error merging files" if merged.length == 0

    merged
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

  def section_number_of(content)
    depth = 0
    section_number = ''
    prev_item = nil
    contents.sort_by(&:weight).each do |item|
      if item[:_type] == 'ChapterSeperator'
        # add sub-sections up to the new chapter depth
        for i in depth...item.depth do
          if i == (item.depth-1)
            section_number += '.0'
          else
            section_number += '.1'
          end
        end

        # drop sub-sections down to the new chapter depth
        for i in item.depth...depth do
          section_number.sub!(/\.\d+\Z/, '')
        end

        # drop off the article section number if we're coming off of articles
        if !prev_item.nil? && (prev_item[:_type] == 'Article')
          section_number.sub!(/\.\d+\Z/, '')
        end

        depth = item.depth
      else # type == Article
        section_number += '.0' if prev_item.nil? || prev_item[:_type] == 'ChapterSeperator'
      end

      section_number.sub!(/(\d+)\Z/) do |m|
        m.to_i + 1 # increment
      end
      return section_number[1..-1] if item == content
      prev_item = item
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

  def build_article
    new_article = contents.build({},Article)
    new_article.build_license
    new_article
  end

  def build_chapter_seperator
    contents.build({},ChapterSeperator)
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