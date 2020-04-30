
# Configure your SMS API settings
require 'net/http'
require 'yaml'
require 'translator'
require 'assigned_package'
require 'sms_package'

class SmsManager
  attr_accessor :recipients, :message
    
  BATCHING_LMIT = 250
    

  def self.split_ids_to_batches(ids)
    ids = fetch_ids_list(ids) if (ids.present? and (ids.include?('all_student') or ids.include?('all_parent') or ids.include?('all_employee')))
    return  ids.to_a.each_slice(BATCHING_LMIT).to_a
  end
    
  def self.fetch_ids_list(ids)
    employee_ids = ids.include?('all_employee') ? Employee.all(:select => :id, :conditions=>["mobile_phone is not NULL and mobile_phone !='' "]).collect(&:id) : [] 
    student_ids =  ids.include?('all_student') ? Student.active.all(:select => :id, :conditions=>["phone2 is not NULL and phone2 !='' "]).collect(&:id) : []
    parent_ids =  ids.include?('all_parent') ? Student.active.all(:select=> :id, :conditions=>  ["immediate_contact_id is NOT NULL"]).collect(&:id) : []
    return ids = employee_ids + student_ids + parent_ids
  end
    
  def self.create_template_based_message_log(template_contents, recipients, group, automated_message)
    message_logs={}
    if template_contents[:student].present? && recipients[:student_ids].present?
      message_logs[:student] = SmsMessage.create(:body=> template_contents[:student], :group_id=> group[:group_id],
        :group_type => group[:group_type], :message_type=> "template_based", :automated_message=> automated_message)
    end 
    if template_contents[:employee].present? && recipients[:employee_ids].present?
      message_logs[:employee] = SmsMessage.create(:body=> template_contents[:employee], :group_id=> group[:group_id],
        :group_type => group[:group_type], :message_type=> "template_based", :automated_message=> automated_message)
    end
    if template_contents[:guardian].present? && recipients[:guardian_sids].present?
      message_logs[:guardian] = SmsMessage.create(:body=> template_contents[:guardian], :group_id=> group[:group_id],
        :group_type => group[:group_type], :message_type=> "template_based", :automated_message=> automated_message)
    end 
    return message_logs
  end
    
  def self.create_plain_message_log(message, group, automated_message)
    message_log =  SmsMessage.create(:body=> message, :group_id=> group[:group_id],
      :group_type => group[:group_type], :message_type=> "plain_message", :automated_message=> automated_message)
    return message_log
  end
    
    
  def self.send_template_based_messages(*args)
    Delayed::Job.enqueue(BulkSmsManager.new(:send_template_based_messages_perform, args), :queue=>'sms')    
  end
  
  def self.send_template_based_messages_perform(template_contents, recipients, group, automated_message, date = nil, all_parents = false, immediate = false)
    #message_log
    message_logs = create_template_based_message_log(template_contents, recipients, group, automated_message)
    #dividing into batches for load shedding  
    batched_student_ids =  split_ids_to_batches(recipients[:student_ids])
    batched_employee_ids = split_ids_to_batches(recipients[:employee_ids])
    batched_guardian_sids = split_ids_to_batches(recipients[:guardian_sids])
    
    if template_contents[:student].present? && recipients[:student_ids].present?
      batched_student_ids.each do |s_ids|
        batched_student_recipients =  {:recipient_type=>"Student", :values => s_ids}
        message = {:content => template_contents[:student], :type => template_contents[:type], :automated_params=>template_contents[:automated_params]}
        sms_manager = new(message, batched_student_recipients, true, message_logs[:student],all_parents, immediate)
        Delayed::Job.enqueue(sms_manager, 0, date,{:queue => 'sms'})
      end
    end
        
    if template_contents[:employee].present? && recipients[:employee_ids].present?
      batched_employee_ids.each do |e_ids|
        batched_employee_recipients =  {:recipient_type=>"Employee", :values => e_ids}
        message = {:content => template_contents[:employee], :type => template_contents[:type], :automated_params=>template_contents[:automated_params]}
        sms_manager = new(message, batched_employee_recipients, true, message_logs[:employee])
        Delayed::Job.enqueue(sms_manager, 0 , date,{:queue => 'sms'})
      end
    end 
    #student_ids are used for fetching guardian
    if template_contents[:guardian].present? && recipients[:guardian_sids].present?
      batched_guardian_sids.each do |s_ids|
        batched_guardian_recipients =  {:recipient_type=>"Guardian", :values => s_ids}
        message = {:content => template_contents[:guardian], :type => template_contents[:type], :automated_params=>template_contents[:automated_params]}
        sms_manager = new(message, batched_guardian_recipients, true, message_logs[:guardian])
        Delayed::Job.enqueue(sms_manager, 0 , date ,{:queue => 'sms'})
      end
    end
  end
    
    
  def self.send_plain_message_perform(message, recipients, group, date = nil, all_parents = false, immediate = false)
    #message_log
    message_log = create_plain_message_log(message, group, false)  

    batched_student_ids =  split_ids_to_batches(recipients[:student_ids])
    batched_employee_ids = split_ids_to_batches(recipients[:employee_ids])
    batched_guardian_sids = split_ids_to_batches(recipients[:guardian_sids])
      
    batched_student_ids.each do |s_ids|
      batched_student_recipients = {:recipient_type=>"Student", :values => s_ids}
      sms_manager = new(message, batched_student_recipients, false, message_log,all_parents, immediate)
      Delayed::Job.enqueue(sms_manager,0, date,{:queue => 'sms'})
    end
      
    batched_employee_ids.each do |e_ids|
      batched_employee_recipients =  {:recipient_type=>"Employee", :values => e_ids}
      sms_manager = new(message, batched_employee_recipients, false, message_log)
      Delayed::Job.enqueue(sms_manager,0, date ,{:queue => 'sms'})
    end
      
    #student_ids are used for fetching guardian
    batched_guardian_sids.each do |s_ids|
      batched_guardian_recipients =  {:recipient_type=>"Guardian", :values => s_ids}
      sms_manager = new(message, batched_guardian_recipients, false, message_log)
      Delayed::Job.enqueue(sms_manager,0,date ,{:queue => 'sms'})
    end
  end
    
  
  def self.send_plain_message(*args)
    Delayed::Job.enqueue(BulkSmsManager.new(:send_plain_message_perform, args), :queue=>'sms')    
  end
    
  def initialize(message, recipients, template_mode=false, message_log=nil, all_parents = false,immediate = false ) 
    @message_log = message_log  if message_log.present?
    @all_parents = all_parents
    @immediate = immediate
    @template_mode = template_mode
    @config = SmsSetting.get_sms_config
    unless @config.blank?
      @sendername = @config['sms_settings']['sendername']
      @sms_url = @config['sms_settings']['host_url']
      @username = @config['sms_settings']['username']
      @password = @config['sms_settings']['password']
      @success_code = @config['sms_settings']['success_code']
      @username_mapping = @config['parameter_mappings']['username']
      @username_mapping ||= 'username'
      @password_mapping = @config['parameter_mappings']['password']
      @password_mapping ||= 'password'
      @phone_mapping = @config['parameter_mappings']['phone']
      @phone_mapping ||= 'phone'
      @sender_mapping = @config['parameter_mappings']['sendername']
      @sender_mapping ||= 'sendername'
      @message_mapping = @config['parameter_mappings']['message']
      @message_mapping ||= 'message'
      unless @config['additional_parameters'].blank?
        @additional_param = ""
        @config['additional_parameters'].split(',').each do |param|
          @additional_param += "&#{param}"
        end
      end
    end
      
    if @template_mode == true
      @recipients = recipients[:values]
      @recipient_type =  recipients[:recipient_type] 
      @template_content =  message[:content]
      @automated_template_properties = {:template_name=> message[:type], :params=> message[:automated_params] } 
    else
      @message = CGI::escape message
      if recipients.class.name == "Hash"
        @new_structure_for_message_send = true
        @recipients = recipients[:values]
        @recipient_type =  recipients[:recipient_type] 
      else
        @recipients = recipients.map{|r| r.to_s.gsub(' ','')}
      end
    end
  end
  

  def perform
    if @template_mode == true
      data_pairs =  build_messages_from_template
      send_data_pairs(data_pairs)
    else
      if @new_structure_for_message_send == true 
        recipient_data = build_recipients
        send_plain_message(recipient_data)
      else 
        common_message_send(@recipients,@message)
      end
    end
  end
    
    
  def common_message_send(recipients, message, user_id=nil, user_name = nil)
    if @message_log.present?
      message_log = @message_log
    else 
      message = message.gsub('+',' ')
      message_log = SmsMessage.new(:body=> message)
      message_log.save
    end
    
    if @template_mode == true
      message_to_be_logged = message
      message =  CGI::escape message
    else 
      message_to_be_logged = nil 
    end   
    if @config.present?
      encoded_message = message
      request = "#{@sms_url}?#{@username_mapping}=#{@username}&#{@password_mapping}=#{@password}&#{@sender_mapping}=#{@sendername}&#{@message_mapping}=#{encoded_message}#{@additional_param}&#{@phone_mapping}="
      ms_present = MultiSchool rescue false
      recipients.each do |recipient|
        if ms_present
          package_used = Configuration.cache_it(['sms_setting',"/#{MultiSchool.current_school.id}/", 'School']) { MultiSchool.current_school.assigned_packages.first(:conditions=>{:is_using=>true},:include=>:sms_package) }
          #package_used = MultiSchool.current_school.assigned_packages.first(:conditions=>{:is_using=>true},:include=>:sms_package)
          unless package_used.nil?
            numbers_to_send = recipient.split(",").count
            size_limit = package_used.sms_package.character_limit.present? ? package_used.sms_package.character_limit : 160
            message_size = ((CGI.unescape(encoded_message).mb_chars.length).to_f/(size_limit).to_f).ceil
            if message_size > 1
              size_limit = package_used.sms_package.multipart_character_limit.present? ? package_used.sms_package.multipart_character_limit : 153
              message_size = ((CGI.unescape(encoded_message).mb_chars.length).to_f/(size_limit).to_f).ceil
            end
            required_msg_count = (numbers_to_send * message_size)
            if (package_used.sms_count.nil? and package_used.validity.nil?)
              can_send_sms = true
            elsif package_used.sms_count.nil?
              can_send_sms = (package_used.validity.to_date >= Date.today)
            elsif package_used.validity.nil?
              can_send_sms = (package_used.sms_count.to_i >= ((package_used.sms_used.to_i)+required_msg_count))
            else
              can_send_sms = ((package_used.sms_count.to_i >= ((package_used.sms_used.to_i)+required_msg_count)) and (package_used.validity.to_date >= Date.today))
            end
          else
            can_send_sms = false
          end
        else
          can_send_sms = true
        end
        if can_send_sms
          cur_request = request
          cur_request += "#{CGI.escape(recipient)}"
          begin
            uri = URI.parse(cur_request)
            http = Net::HTTP.new(uri.host, uri.port)
            if cur_request.include? "https://"
              http.use_ssl = true
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end
            get_request = Net::HTTP::Get.new(uri.request_uri)
            response = http.request(get_request)
            if response.body.present?
              message_log.sms_logs.create(:mobile=>recipient,:gateway_response=>response.body, :message=>message_to_be_logged, :user_id=> user_id,:user_name => user_name)
              if @success_code.present?
                if response.body.to_s.include? @success_code
                  sms_count = Configuration.find_by_config_key("TotalSmsCount")
                  new_count = sms_count.config_value.to_i + 1
                  sms_count.update_attributes(:config_value=>new_count)
                  if ms_present
                    package_used.reload
                    package_used.update_attributes(:sms_used=>(package_used.sms_used.to_i + required_msg_count))
                  end
                end
              end
            end
          rescue Timeout::Error => e
            message_log.sms_logs.create(:mobile=>recipient,:gateway_response=>e.message, :message=>message_to_be_logged, :user_id=> user_id,:user_name => user_name)
          rescue Errno::ECONNREFUSED => e
            message_log.sms_logs.create(:mobile=>recipient,:gateway_response=>e.message, :message=>message_to_be_logged, :user_id=> user_id,:user_name => user_name)
          rescue Exception => e
            message_log.sms_logs.create(:mobile=>recipient,:gateway_response=>e.message, :message=>message_to_be_logged, :user_id=> user_id,:user_name => user_name)
          end
        else
          message_log.sms_logs.create(:mobile=>recipient,:gateway_response=>"#{I18n.t('package_expired')}", :message=>message_to_be_logged, :user_id=> user_id, :user_name => user_name)
        end
      end
    else
      message_log.sms_logs.create(:mobile=>recipients.join(", "),:gateway_response=>"#{I18n.t('package_not_assigned')}", :message=>message_to_be_logged, :user_id=> user_id, :user_name => user_name)
    end 
  end
    
    
  def build_messages_from_template
    message_builder = MessageBuilder.new
    data_pairs = []
    if @recipient_type == "Student"
      data_pairs = message_builder.student_message_send(@recipients, @template_content, @automated_template_properties)
    elsif @recipient_type == "Employee"
      data_pairs = message_builder.employee_message_send(@recipients, @template_content, @automated_template_properties)
    elsif @recipient_type == "Guardian"
      data_pairs = message_builder.guardian_message_send(@recipients, @template_content, @automated_template_properties)
    else 
    end
    return data_pairs
  end
    
  def send_data_pairs(data_pairs)
    user_ids = []
    data_pairs.each do |data_pair|
      user_ids << data_pair[2]
      send_a_parents_copy(data_pair) if @all_parents or @immediate
      common_message_send(data_pair[0].to_a, data_pair[1], data_pair[2])
    end
    send_copy(user_ids) if @all_parents or @immediate
  end
  
  
  def fetch_message(template_content, user_id)
    @automated_template_name = @automated_template_properties[:template_name]
    @automated_params = @automated_template_properties[:params]
    message_builder = MessageBuilder.new
    message_template = message_builder.build_message_template({:student=>template_content})
    if @automated_template_name.present?
      message_template.automated_template_name = @automated_template_name.to_s
      message_template.template_type = "AUTOMATED" 
    end
    if validate_message_template(message_template) == false
      return report_errors
    end
    keys =  message_template.get_included_keys
    common_keys = message_template.get_common_keys
    content = message_template.student_template_content.content
    student = fetch_students(message_template, user_id)
    key_replacer = KeyReplacer.new
    key_replacer.replace_student_keys(content,student.first,keys[:student])
    key_replacer.replace_common_keys(common_keys, student.first)
    if @automated_template_name.present?
      automated_keys = build_automated_keys(student.first, :student)
      key_replacer.replace_automated_keys(automated_keys)
    end
    return key_replacer.get_content
  end
  
  def validate_message_template(message_template)
    if message_template.valid?
      return true
    else
      @errors.concat(message_template.errors.full_messages)
      return false 
    end
  end
  
  def fetch_students(message_template,user_id)
    student_ids = Student.all(:select => :id,:conditions=>["user_id = ? ", user_id]).collect(&:id)
    student_keys =  message_template.get_included_keys[:student]
    message_builder = MessageBuilder.new
    includes = message_builder.get_student_includes(student_keys)
    named_scope = message_builder.get_student_named_scope(student_keys)
    if named_scope.present?
      student =  Student.send(named_scope, student_ids).all(:include=> includes)
    else
      student =  Student.all(:conditions=>["user_id = ? ", user_id],:include=> includes)
    end
    return student
  end
  
  def send_copy(user_ids)
    student_user_ids =  Student.all(:select => :user_id,:conditions=>["id in (?)", @recipients]).collect(&:user_id)
    std_without_number = student_user_ids.reject{|std| user_ids.include?(std) }
    if std_without_number.present?
      std_without_number.each do |user_id|
        message = fetch_message(@template_content,user_id)
        data_pair = ['', message, user_id ]
        send_a_parents_copy(data_pair)
      end
    end
  end
  
  def send_a_parents_copy(data_pair)
    @log = Logger.new('log/birthday.log')
    student =  Student.all(:conditions=>["user_id = ?",data_pair[2]], :include=>[:immediate_contact])
    guardians = student.collect(&:immediate_contact).compact if @immediate 
    guardians = student.first.guardians.compact if @all_parents 
    guardians.each do |guardian|
      parents_data_pairs = []
      parents_data_pairs << guardian.mobile_phone 
      parents_data_pairs << data_pair[1]
      parents_data_pairs << guardian.user_id 
      parents_data_pairs << guardian_full_name(guardian)
      common_message_send(parents_data_pairs[0].to_a, parents_data_pairs[1], parents_data_pairs[2],parents_data_pairs[3])
    end
  end
    
  def guardian_full_name(guardian)
    return "#{guardian.first_name} #{guardian.last_name}"
  end
  
  def build_recipients
    recipient_data = []
    message_builder = MessageBuilder.new
    if @recipient_type == "Student"
      recipient_data = message_builder.build_student_recipient_details(@recipients)
    elsif @recipient_type == "Employee"
      recipient_data = message_builder.build_employee_recipient_details(@recipients)
    elsif @recipient_type == "Guardian"
      recipient_data = message_builder.build_guardian_recipient_details(@recipients)
    elsif @recipient_type == "ApplicantStudent"
      recipient_data = message_builder.build_applicant_student_recipient_details(@recipients)  
    elsif @recipient_type == "ApplicantGuardian"
      recipient_data = message_builder.build_applicant_guardian_recipient_details(@recipients)  
    else 
    end
    return recipient_data  
  end
    
  def send_plain_message(recipient_data)
    recipient_data.each do |recipient_detail|
      phone_nos = recipient_detail[0].to_a
      user_id = recipient_detail[1] 
      user_name = recipient_detail[2]
      common_message_send(phone_nos,@message,user_id, user_name) 
      send_a_parents_plain_copy(user_id) if @all_parents or @immediate
    end
  end
    
  def send_a_parents_plain_copy(user_id)
    student =  Student.all(:conditions=>["user_id = ?",user_id], :include=>[:immediate_contact])
    guardians = student.collect(&:immediate_contact).compact if @immediate 
    guardians = student.first.guardians.compact if @all_parents 
    guardians.each do |guardian|
      parents_data_pairs = []
      parents_data_pairs << guardian.mobile_phone 
      parents_data_pairs << @message
      parents_data_pairs << guardian.user_id 
      parents_data_pairs << guardian_full_name(guardian)
      common_message_send(parents_data_pairs[0].to_a, parents_data_pairs[1], parents_data_pairs[2],parents_data_pairs[3])
    end
  end
  
end

