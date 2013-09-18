module LicenseHelper
  def type_options
    License::TYPES.map{|type| [nice_type(type),type]}
  end

  def nice_type(type)
    # for cc licenses, translate through the creative_commons_rails gem
    if type =~ /\Acc_/
      cc_type = I18n.t type.to_s.sub(/\Acc_/, 'license_type_'), version: '', jurisdiction: ''
      I18n.t :license_title, license_type: cc_type
    else
      type.titleize
    end
  end

  def cc_jurisdiction_options
    CreativeCommonsRails::LicenseInfo::available_jurisdictions.map{|j| [I18n.t(j), j]}
  end

  def cc_version_options(license)
    versions = CreativeCommonsRails::LicenseInfo::available_versions(license.jurisdiction, license.type.sub(/\Acc_/,''))
    versions.map{|v| [v,v]}
  end
end