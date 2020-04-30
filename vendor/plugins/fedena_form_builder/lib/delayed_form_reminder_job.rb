require 'logger'
class DelayedFormReminderJob
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper
  include Notifier
  attr_accessor :form
  def initialize(form,host,new_recipients = [])
    recipients = []
    log = Logger.new('log/reminder_new.log')    
    log.info(new_recipients)
    @recipients_array = []    
    unless form.is_public
      if new_recipients.present?
        students = User.find_all_by_id(new_recipients,:conditions => {:student => true}).map(&:id)
        employees = new_recipients - students
      end
        
      students = form.students.split(',') unless new_recipients.present?
      employees = form.members.split(',') - students unless new_recipients.present?
      case form.is_parent
      when 0
        Student.find_all_by_user_id(students,:select => "students.*",:joins=>"INNER JOIN `guardians` ON guardians.id = students.immediate_contact_id").collect {
          |x|
          recipients << x.immediate_contact.user_id
        }
      when 1
        recipients << students
      when 2
        Student.find_all_by_user_id(students,:select => "students.*",:joins=>"INNER JOIN `guardians` ON guardians.id = students.immediate_contact_id").collect {
          |x|
          recipients << x.immediate_contact.user_id
        }
        recipients << students
      end
      recipients.delete nil
      @recipients_array << employees
      @recipients_array << recipients
      @recipients_array = @recipients_array.flatten.uniq
    end    
    
    
    form_path = "#{Fedena.hostname}/forms/#{form.id}"
    @form_link = "#{link_to form_path,form_path,:class=>'themed_text'}".html_safe
    @form_id = form.id
    @sender = form.user_id
    @form_name = form.name
    @form_is_public = form.is_public
  end

  def perform
    if(@form_is_public)
      subject = "#{I18n.t('new_form_published', :form_name=>@form_name )}"
      body = "#{subject}<span class='embeded_links'>#{@form_link}</span>"
      News.create(:title => subject,:content => body, :author_id => @sender)
    else
      body = "<b>#{@form_name}</b> #{I18n.t('is_published')} "
      links = {:target=>'view_form',:target_params=>'form_id',:target_value=>@form_id}
      recipient_ids = @recipients_array.flatten.compact
      recipient_ids.each do |recp_id|
        inform([recp_id],body,'Form',links)
      end
    end    
  end



end