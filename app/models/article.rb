require 'pdf_utils'
require 'swf_utils'

class Article
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :course_pack
  field :title, type: String, default: ""
  field :author, type: String
  field :reference, type: String
  field :num_pages, type: Integer
  field :page_start, type: Integer
  field :page_end, type: Integer
  field :weight, type: Integer, default: 0 #controls order of appearance in the CoursePack
  mount_uploader :file, DocUploader
  attr_accessible :title, :author, :reference, :num_pages, :page_start, :page_end, :file, :weight
  attr_accessor :temp_id

  after_save :count_pages

  def initialize(attributes, options)
    super(attributes, options)

    # also initialize the non-persistent temp_id
    @temp_id = attributes[:temp_id]
  end

  def trimmed?
    (!page_start.nil? && page_start > 1) || (!page_end.nil? && page_end < num_pages)
  end

  def trimmed_swf(outfile = nil)
    raise 'No SWF file found' if file.swf.path.nil?

    # save to a temp file if no outfile is specified
    if outfile.nil?
      outfile = Tempfile.new(["#{id}-trimmed",".swf"])
    end

    if !trimmed?
      FileUtils.copy(file.swf.path, outfile)
    else
      pages = trimmed_page_range
      SwfUtils::extract_pages(file.swf.path, outfile.path, "#{pages[0]-1}-#{pages[1]-1}")
    end

    outfile
  end

  def as_json(options={})
    result = super(options)
    result[:temp_id] = temp_id
    result
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