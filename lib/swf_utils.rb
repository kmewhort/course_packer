module SwfUtils
  # merge the input swf files together, using SwfTools
  def self.merge(input_files, output_file)
    raise "No input files specified" if input_files.nil? || input_files.empty?

    if input_files.length == 1
      FileUtils.copy input_files[0], output_file
    else
      `swfcombine --cat #{input_files.join(' ')} -o #{output_file}`
    end
  end

  # extract specified page numbers, using SwfTools (see SwfTools docs for the page_range format)
  def self.extract_pages(input_file, output_file, page_range)
    # check the page_range parameter for invalid characters
    raise 'Invalid page range format ' if page_range =~ /[^\,\s0-9\-\s]/

    `swfextract -o #{output_file} -f #{page_range} #{input_file}`
    raise 'Error executing swfextract' unless $?.exitstatus == 0
  end
end