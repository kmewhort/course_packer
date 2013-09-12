module SwfUtils
  # merge the input swf files together, using SwfTools
  def self.merge(input_files, output_file)
    raise "No input files specified" if input_files.nil? || input_files.empty?

    if input_files.length == 1
      FileUtils.copy input_files[0], output_file
    else
      `swfcombine --cat #{input_files.join(' ')} -o #{output_file}`
      raise 'Error executing swfcombine' unless $?.exitstatus == 0
    end
  end

  # stamp page numbers onto document, using SwfUtils
  def self.stamp_page_numbers(input_file, num_pages, output_file)
    # use the smallest available page number template
    template_file = nil
    [25,50,200,500,1000,5000,10000].each do |template_size|
      if template_size >= num_pages
        template_file = "#{File.dirname(__FILE__)}/swf_utils/page_numbers/pagenumbers_1_#{template_size}.swf"
        break
      end
    end
    raise "Unable to find sufficiently large page number template file." if template_file.nil?

    # overlay the page numbers
    `swfcombine -tm #{input_file} #{template_file} -o #{output_file}`
    raise 'Error executing swfcombine' unless $?.exitstatus == 0
  end

  # extract specified page numbers, using SwfTools (see SwfTools docs for the page_range format)
  def self.extract_pages(input_file, output_file, page_range)
    # check the page_range parameter for invalid characters
    raise 'Invalid page range format ' if page_range =~ /[^\,\s0-9\-\s]/

    `swfextract -o #{output_file} -f #{page_range} #{input_file}`
    raise 'Error executing swfextract' unless $?.exitstatus == 0
  end
end