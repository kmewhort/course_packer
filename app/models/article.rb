require 'pdf_utils'

class Article < Content

  field :author, type: String
  field :reference, type: String
  field :num_pages, type: Integer
  field :page_start, type: Integer
  field :page_end, type: Integer
  mount_uploader :file, DocUploader
  attr_accessible :author, :reference, :page_start, :page_end, :file, :weight

  after_save :count_pages

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

  def trimmed_pdf(outfile = nil)
    raise 'No PDF file found' if file.pdf.path.nil?

    # save to a temp file if no outfile is specified
    if outfile.nil?
      outfile = Tempfile.new(["#{id}-trimmed",".pdf"])
    end

    if !trimmed?
      FileUtils.copy(file.pdf.path, outfile)
    else
      pages = trimmed_page_range
      PdfUtils::extract_pages(file.pdf.path, outfile.path, "#{pages[0]-1}-#{pages[1]-1}")
    end

    outfile
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