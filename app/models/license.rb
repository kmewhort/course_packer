class License
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :article

  field :type, type: String, default: 'fair_dealing'
  TYPES = %w(fair_dealing library_site_license cc_by cc_by_sa cc_by_nd cc_by_nc cc_by_nc_sa cc_by_nc_nd)

  field :jurisdiction, type: String
  field :version, type: String

  attr_accessible :type, :jurisdiction, :version, :id

  def full_title
    # leave license title blank for fair dealing or library site license
    return nil if self.type.nil? || (self.type == 'fair_dealing') || (self.type == 'library_site_license')

    unless cc_license_info.nil?
      cc_license_info.translated_title
    else
      self.type.titleize
    end
  end

  def url
    # only implemented for CC
    unless cc_license_info.nil?
      cc_license_info.deed_url
    else
      nil
    end
  end

  def pdf_attribution_footer(outfile = nil)
    # only implemented for CC
    if cc_license_info.nil?
      return nil
    end

    html = ApplicationController.new.render_to_string(partial: 'pdf/attribution',
                                                      locals: { license: self, license_info: cc_license_info } )

    html_file = Tempfile.new(["#{id}-attribution",".html"])
    html_file.write html
    html_file.close(false)

    # save to a temp file if no outfile is specified
    if outfile.nil?
      outfile = Tempfile.new(["#{id}-attribution",".pdf"])
    end

    pdf_kit = PDFKit.new(File.new(html_file.path), :page_size => 'Letter',
                         :margin_bottom => '0in', :no_background => true)
    pdf_kit.to_file(outfile.path)
    outfile
  end

  def creative_commons?
    !(type =~ /\Acc_/).nil?
  end

  # for a CC license, set a default jurisdiction and version
  def update_defaults
    if creative_commons?
      self.jurisdiction = 'unported' if self.jurisdiction.nil?
      self.version = "3.0" if self.version.nil?
    end
  end

  private
  def cc_license_info
    if creative_commons? && !self.jurisdiction.nil? && !self.version.nil?
      CreativeCommonsRails::LicenseInfo.new(self.type.sub(/cc_/,''), self.jurisdiction, self.version)
    else
      nil
    end
  end
end
