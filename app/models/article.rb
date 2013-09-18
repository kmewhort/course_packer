require 'pdf_utils'

class Article < Content

  field :author, type: String
  field :reference, type: String
  field :num_pages, type: Integer
  field :page_start, type: Integer
  field :page_end, type: Integer
  mount_uploader :file, DocUploader
  attr_accessible :author, :reference, :page_start, :page_end, :file, :weight, :license_attributes

  embeds_one :license
  accepts_nested_attributes_for :license, allow_destroy: true

  after_save { self.reload; count_pages }

  def has_file?
    !file.path.nil?
  end

  def trimmed?
    (!page_start.nil? && page_start > 1) || (!page_end.nil? && page_end < num_pages)
  end

  def num_pages_after_trimming
    return 0 unless has_file?
    range = trimmed_page_range
    range[1] - range[0] + 1
  end

  # article in pdf, page trimmed and attribution stamped
  # note: may return a Tempfile (not unlinked)
  def prepared_pdf
    raise 'No PDF file found' if file.pdf.path.nil?

    trimmed = if !self.trimmed?
      self.file.pdf
    else
      # save trimmed article to a temp file
      temp = Tempfile.new(["#{id}-trimmed",".pdf"])
      pages = trimmed_page_range
      PdfUtils::extract_pages(file.pdf.path, temp.path, "#{pages[0]-1}-#{pages[1]-1}")
      temp
    end

    attributed = trimmed
    if !license.nil?
      footer = license.pdf_attribution_footer
      unless footer.nil?
        attributed = Tempfile.new(["#{id}-attributed",".pdf"])
        PdfUtils::overlay(trimmed.path, footer.path, attributed.path)
      end
    end

    attributed
  end

  private
  # count the number of pages in the document
  def count_pages
    unless @destroyed
      pages = file.path.nil? ? nil : PdfUtils::count_pages(file.pdf.path)
      set(:num_pages, pages)
    end
  end

  def trimmed_page_range
    [(page_start.nil? || page_start < 1) ? 1 : page_start,
     (page_end.nil? || page_end > num_pages) ? num_pages : page_end]
  end
end