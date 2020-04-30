class ApplicantNotifier < ActionMailer::Base
  def send_update_notification(applicant_full_name,email,reg_no,reg_course_name,status_name, school_details,hostname)
    @recipients  = email
    @subject     = "Application Status Update Notification"
    @sent_on     = Time.now
    @school =  Configuration.get_config_value('InstitutionName')
    @full_name = applicant_full_name
    @reg_no = reg_no
    @reg_course_name = reg_course_name
    @status_name = status_name
    @footer = "#{t("footer",{:school_name=>Configuration.get_config_value('InstitutionName'),:school_details=> school_details})}"
    @hostname= hostname
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
