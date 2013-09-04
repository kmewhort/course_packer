module PdfUtils
  # merge multiple pdfs into one, using pdftk
  def self.merge(input_files, output_file, end_on_even = false)
    raise "No input files specified" if input_files.nil? || input_files.empty?

    input_file_str = input_files.join(' ')

    if end_on_even
      page_count = input_files.map{|f| count_pages(f)}.reduce(0, :+)
      if page_count % 2 == 1
        blank_page = "#{File.dirname(__FILE__)}/pdf_utils/blanks/blank_standard.pdf"
        input_file_str += ' ' + blank_page
      end
    end

    `pdftk #{input_file_str} cat output #{output_file}`
  end

  # extract bookmarks in a pdf (to an array), using jpdfbookmarks
  def self.bookmarks(input_file)
    output = `LANG=\"en_US.UTF8\" jpdfbookmarks --dump #{input_file} -t~ -i* -p# --encoding UTF-8"`
    raise 'Error executing jpdfbookmarks' unless $?.exitstatus == 0

    bookmarks = output.map do |line|
      keys = ['title_and_page', 'colour', 'bold', 'italic', 'open', 'positiontype', 'y', 'x']
      vals = line.split('~')[0..8]
      data = Hash[[keys,vals].transponse]

      data['title_and_page'] = data['title_and_page'].split('#')
      data['title'] = data['title_and_page'][0]
      data['page'] = data['title_and_page'][1]
    end
  end

  # count the number of pages, using pdftk
  def self.count_pages(input_file)
    result = `pdftk #{input_file} dump_data | grep -i NumberOfPages`
    if result =~ /(\d+)\s*\Z/
      $1.to_i
    else
      raise "Error retrieving page numbers from pdftk"
    end
  end

  # stamp page numbers onto document, using pdftk
  def self.stamp_page_numbers(input_file, output_file)
    # use the smallest available page number template
    num_pages = count_pages(input_file)
    template_file = nil
    [25,50,200,500,1000,5000,10000].each do |template_size|
      next unless template_size >= num_pages

      template_file = "#{File.dirname(__FILE__)}/pdf_utils/page_numbers/page_numbers_1_#{template_size}.pdf"
    end
    raise "Unable to find sufficiently large page number template file." if template_file.nil?

    # merge the page numbers into the pdf as a background
    `pdftk #{input_file} multistamp #{template_file} output #{output_file}`
    raise 'Error executing pdftk' unless $?.exitstatus == 0
  end

  # extract specified page numbers, using pdftk (see pdftk docs for the page_range format)
  def self.extract_pages(input_file, output_file, page_range)
    # check the page_range parameter for invalid characters
    raise 'Invalid page range format ' if page_range =~ /[^\,\s0-9\-\s]/

    `pdftk #{input_file} cat #{page_range} output #{output_file}`
    raise 'Error executing pdftk' unless $?.exitstatus == 0
  end
end