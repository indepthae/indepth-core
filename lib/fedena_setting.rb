class FedenaSetting

  cattr_accessor :sms_settings_from_yml, :smtp_settings_from_yml, :company_settings_from_yml
  cattr_reader :s3_settings_from_yml

  @@sms_settings_from_yml = YAML.load_file(File.join(Rails.root,"config","sms_settings.yml"))[RAILS_ENV] if File.exists?("#{Rails.root}/config/sms_settings.yml")
  @@smtp_settings_from_yml = YAML.load_file(File.join(Rails.root,"config","smtp_settings.yml"))[RAILS_ENV] if File.exists?("#{Rails.root}/config/smtp_settings.yml")
  @@company_settings_from_yml = YAML.load_file(File.join(Rails.root,"config","company_details.yml")) if File.exists?("#{Rails.root}/config/company_details.yml")
  @@s3_settings_from_yml = YAML.load_file(File.join(Rails.root,"config","amazon_s3.yml")) if File.exists?("#{Rails.root}/config/amazon_s3.yml")

  def initialize
    
  end

  def self.company_details
    FEDENA_SETTINGS
  end

  def self.smtp_settings
    SMTP_SETTINGS
  end

  def self.s3_settings
    if s3_settings_from_yml
      s3_settings_from_yml[RAILS_ENV]
    end
  end

  def self.s3_enabled?
    File.exist?("#{Rails.root}/config/amazon_s3.yml")
  end

  class S3
    @@keys = FedenaSetting.s3_settings.try(:keys) || []
    class << self
      def method_missing (name, *args, &block)
        if @@keys.include? name.to_s
          FedenaSetting.s3_settings[name.to_s]
        else
          super(name, *args, &block)
        end
      end
    end
  end
  
end
