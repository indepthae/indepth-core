# To change this template, choose Tools | Templates
# and open the template in the editor.

class AdminUserNotifier < ActionMailer::Base
  def forgot_password(admin_user,current_url)
    if admin_user.class.name == "MultiSchoolAdmin"
      ms_group = admin_user.multi_school_group
      if ms_group.effective_smtp_settings.nil?
        self.class.smtp_settings = SMTP_SETTINGS
      else
        self.class.smtp_settings = ms_group.effective_smtp_settings
      end
    else
      self.class.smtp_settings = SMTP_SETTINGS
    end
    setup_email(admin_user,current_url)
    @subject    += 'Reset Password'
    @body[:url]  =  current_url+"/admin_users/reset_password/#{admin_user.reset_password_code}"
  end

  def notify_creation(school,client,master_admin)
    setup_notice(school,client,master_admin)
    @subject = "Fedena Saas School creation notification"
  end

  def notify_deletion(school,client,master_admin)
    setup_notice(school,client,master_admin)
    @subject = "Fedena Saas School deletion notification"
  end

  protected
  def setup_email(admin_user, current_url)
    @recipients  = "#{admin_user.email}"
    #admin_email = AdminUser.find_by_username('admin').email
    admin_email = "noreply@#{get_domain(current_url)}"
    @from        = admin_email
    @subject     = " "
    @sent_on     = Time.now
    @body[:admin_user] = admin_user
  end

  def setup_notice(school,client,master_admin)
    @recipients = "#{master_admin.email}"
    @sent_on = Time.now
    @body[:master_admin] = master_admin
    @body[:school_name] = school.name
    @body[:client_name] = client.name
    @content_type = "text/html"
  end

  def get_domain(current_url)
    url_parts = current_url.split("://").last.split('.')
    url_parts[(url_parts.length - 2) .. (url_parts.length - 1)].join('.')
  end
end
