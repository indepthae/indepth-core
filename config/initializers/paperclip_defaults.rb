
Paperclip.interpolates :timestamp do |attachment,style|
  attachment_update_at = attachment.name.to_s + "_updated_at"
  attachment.instance.send(attachment_update_at).present? ? attachment.instance.send(attachment_update_at).strftime('%Y%m%d%H%m%S') : nil
end
Paperclip.interpolates :attachment_fullname do |attachment,style|
  file_name=attachment.name.to_s + "_file_name"
  URI.escape(attachment.instance.send(file_name)).gsub('+','%2B').gsub("[","%5B").gsub("]","%5D")
end
if  FedenaSetting.s3_enabled?
  require 'aws/s3'
  require 'aws_extension'
  require 'cloudfront_signer'
  
  {
    :storage=>:s3,
    :s3_credentials=>{
      :bucket => Config.bucket_private,
      :access_key_id =>  Config.access_key_id,
      :secret_access_key => Config.secret_access_key
    },
    :s3_host_alias=>Config.cloudfront_private,
    :url => ':s3_alias_url',
    :s3_permissions=>:private

  }.each do |k,v|
    Paperclip::Attachment.default_options.merge! k=>v
  end

  AWS::CF::Signer.configure do |config|
    config.key_path = FedenaSetting::S3.cloudfront_signing_key_path
    config.key_pair_id  = FedenaSetting::S3.cloudfront_signing_key_pair_id
    config.default_expires = 3600
  end

  Paperclip.interpolates(:s3_alias_url) do |attachment, style|
    url ="#{attachment.s3_protocol}://#{attachment.s3_host_alias}/#{URI.encode(attachment.path(style)).gsub('+','%2B').gsub(%r{^/}, "").gsub("[","%5B").gsub("]","%5D")}"
    AWS::CF::Signer.sign_url(url)
  end unless Paperclip::Interpolations.respond_to? :s3_alias_url

  ActiveRecord::Base.instance_eval do
    def has_attached_file name, options = {}
      super name, options
      attachment_definitions[name][:url] = ":s3_alias_url"
      attachment_definitions[name][:path] = options[:path].gsub(":basename", ":timestamp/:basename").gsub(":attachment_fullname", ":timestamp/:attachment_fullname")
    end
  end
  
  Paperclip.interpolates :id_partition do |attachment,style|
    attachment.instance.id
  end  
  
  Paperclip.interpolates :assignment_id do |attachment,style|
    attachment.instance.assignment_id
  end
  
  Paperclip.interpolates :school_id do |attachment,style|
    attachment.instance.school_id
  end
else # file system
  Paperclip.interpolates :school_id do |school, style|
    custom_id_partition school.instance.school.id
  end
end

require 'jwt_url_signer'

JWT::UrlSigner.configure

if JWT::UrlSigner.signing_enabled?

  Paperclip.interpolates :jwt_signed_url do |att, style|
    url = "#{Fedena.hostname}#{att.send(:interpolate, att.options[:orig_url])}"  
    is_redactor_file = url.match(/uploads\/redactor_uploads\/\d+/) ? true : false
    signed_url = is_redactor_file ? url : JWT::UrlSigner.sign_url(url)    
    signed_url    
  end

  ActiveRecord::Base.instance_eval do
    def has_attached_file name, options = {}
      super name, options
      attachment_definitions[name][:orig_url] = options[:url]
      attachment_definitions[name][:url] = ":jwt_signed_url"
    end
  end

end

