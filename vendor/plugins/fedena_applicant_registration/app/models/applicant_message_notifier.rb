class ApplicantMessageNotifier < ActionMailer::Base
  def send_message_notification(email_ids, email_subject, email_content, hostname, school_details)
    @recipients  = email_ids
    @subject     = email_subject
    @sent_on     = Time.now
    @school =  Configuration.get_config_value('InstitutionName')
    @applicant_content = email_content
    @hostname = hostname
    @footer = "#{t("footer",{:school_name=>Configuration.get_config_value('InstitutionName'),:school_details=> school_details})}"
    @content_type="text/html; charset=utf-8"
  end
  
  private

  def msg_parse(k)
    str={}
    k.each do |w|
      str.merge!( w.gsub(".","_").to_sym=>"#{self.instance_eval(w)}")
    end
    return str
  end
end
