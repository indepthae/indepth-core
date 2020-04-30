# To change this template, choose Tools | Templates
# and open the template in the editor.

class SmtpSetting < AdditionalSetting

  SETTING_FIELDS = [:enable_starttls_auto,:address,:port,:user_name,:password,:authentication,:domain, :from_address]

  before_save :set_types

  def set_types
    if self.settings["enable_starttls_auto"].strip == "true" || self.settings["enable_starttls_auto"] == true
      self.settings["enable_starttls_auto"] = true
    else
      self.settings["enable_starttls_auto"] = false
    end
    self.settings["port"] = self.settings["port"].to_i
    self.settings["authentication"] = self.settings["authentication"].to_sym unless self.settings["authentication"].blank?
  end

  def self.send_test_mail(user,owner)
    smtp_settings = owner.smtp_setting.settings_to_sym
    smtp = Net::SMTP.new(smtp_settings[:address], smtp_settings[:port])
    smtp.enable_starttls_auto if smtp_settings[:enable_starttls_auto] && smtp.respond_to?(:enable_starttls_auto)
    from = smtp_settings[:from_address]
    from = from.blank? ? 'noreply@fedena.com' : from
    m = TMail::Mail.new
    m['from'] = from
    m['return-path'] = from
    m.subject="Testing SMTP settings for #{owner.name}"
    m.body="This is a test mail. If you are recieving this mail, then the Email settings provided for #{owner.name} #{owner.class.name.titleize} is working perfectly. \nThank You"
    smtp.start(smtp_settings[:domain], smtp_settings[:user_name], smtp_settings[:password],
      smtp_settings[:authentication]) do |s|
      s.sendmail(m.encoded, from, [user.email])
    end


  end

end
