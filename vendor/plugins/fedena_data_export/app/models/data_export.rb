class DataExport < ActiveRecord::Base
  require 'fileutils'
  require 'nokogiri'

  belongs_to :export_structure
  attr_accessor :job_type,:model_ids,:blank_file

  validates_presence_of :file_format

  has_attached_file :export_file,
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
    :url => "/data_exports/:id/download_export_file",
    :max_file_size => 52428800,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types =>[]

  validates_attachment_size :export_file, :less_than => 52428800,\
    :message=>'must be less than 50 MB.',:if=> Proc.new { |p| p.export_file_file_name_changed? }

  class DataExportValidationError < StandardError
  end

  def status_message
    case status
    when 'Success'
      status
    when 'In progress','In progess'
      'In progress'
    else
      'Failed'
    end
  end

  def perform
    begin
      @export_file_str = "tmp/#{Time.now.strftime("%H%M%S%d%m%Y")}_#{export_structure.model_name}.#{file_format}"
      remove_old_entry
      make_file
      self.export_file = File.open(@export_file_str)
      raise DataExportValidationError, self.errors.full_messages unless save
    rescue Exception=>e
      self.reload
      self.update_attribute(:status,e.message)
    ensure
      File.delete(@export_file_str) if File.exist?(@export_file_str)
    end

    prev_record = Configuration.find_by_config_key("job/DataExport/#{self.job_type}")
    if prev_record.present?
      prev_record.update_attributes(:config_value=>Time.now)
    else
      Configuration.create(:config_key=>"job/DataExport/#{self.job_type}", :config_value=>Time.now)
    end
  end

  def remove_old_entry
    update_attributes(:status => "In progress")
    data_export = export_structure.data_export
    if (data_export.present? and data_export.id != id)
      export_structure.data_export.destroy
    end
  end

  def make_file
    file_format == "csv" ? csv_data_export : make_xml_file
    update_attributes(:status => "Success")
  end

  def check_database
    config = Configuration.find_by_config_key("StudentAttendanceType").config_value
    if export_structure.model_name == "attendance" and  config == "SubjectWise"
      SubjectLeave.first.nil?
    else
      export_structure.model_name.camelize.constantize.first.nil?
    end
  end

  def make_blank_xml_file
    @file << '<?xml version="1.0" encoding="UTF-8"?><xml_error_detail><xml_error><error>Blank Database</error></xml_error></xml_error_detail>'
    update_attributes(:status => "Success")
  end

  def get_template
    if export_structure.plugin_name.nil?
      template_file = ERB.new File.new("#{Rails.root}/app/views#{export_structure.template}").read, 0, ">"
    else
      template_file = ERB.new File.new("#{Rails.root}/vendor/plugins/#{export_structure.plugin_name}/app/views#{export_structure.template}").read, 0, ">"
    end
    template_file
  end

  def make_xml_file
    @file = open(@export_file_str,'w')
    if check_database
      make_blank_xml_file
    else
      i = 0
      xml_start_tag = String.new
      xml_close_tag = String.new
      export_structure.model_name.camelize.constantize.send(export_structure.make_query.first,export_structure.make_query.second.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}) do |block_datas|
        instance_variable_set("@" + export_structure.model_name.pluralize,block_datas)
        @xml = Builder::XmlMarkup.new
        template_file = get_template
        xml_file_content = template_file.result(get_binding)
        made_xml = make_xml_data(xml_file_content)
        xml_start_tag = made_xml.second
        xml_close_tag = made_xml.third
        xml_data = made_xml.first
        start_xml_file(xml_start_tag) if i == 0
        append_file_data(xml_data)
        i += 1
        break if export_structure.model_name == "configuration"
      end
      finish_xml_file(xml_close_tag)
    end
    @file.close
  end

  def make_xml_data(xml_file_content)
    xml_data = delete_xml_content_info(xml_file_content.to_s)
    xml_data = delete_start_xml_tag(xml_data)
    start_tag = xml_data.second
    xml_data = delete_closing_xml_tag(xml_data.first)
    closing_tag = xml_data.second
    xml_data = xml_data.first
    [xml_data,start_tag,closing_tag]
  end

  def delete_closing_xml_tag(xml_file_content)
    xml_file_content = xml_file_content.reverse
    slice_index = xml_file_content.index('<')
    end_tag = xml_file_content.slice!(0,slice_index + 1).reverse
    [xml_file_content.reverse,end_tag]
  end

  def delete_start_xml_tag(xml_file_content)
    xml_file_content = xml_file_content
    slice_index = xml_file_content.index('>')
    start_tag = xml_file_content.slice!(0,slice_index + 1)
    [xml_file_content,start_tag]
  end

  def delete_xml_content_info(xml_file_content)
    xml_file_content = xml_file_content.gsub('<?xml version="1.0" encoding="UTF-8"?>',"")
  end

  def start_xml_file(xml_start_tag)
    @file << '<?xml version="1.0" encoding="UTF-8"?>'
    @file << xml_start_tag
  end

  def append_file_data(file_content)
    @file << file_content
  end

  def finish_xml_file(xml_close_tag)
    @file << xml_close_tag
  end

  def default_block_data_count
    export_structure.query[export_structure.query.keys.first][:batch_size]
  end
  def subject_leave_csv_header_order
    config_enable = Configuration.get_config_value('CustomAttendanceType') || "0" 
    if Configuration.enabled_roll_number?
      if config_enable == '1'
        return ["student_admission_no","roll_number","subject_name","status_name", "attendance_type","class_timing_name","batch_name","reason","date"]
      else
        return ["student_admission_no","roll_number","subject_name","class_timing_name","batch_name","reason","date"]
      end
    else
      if config_enable == '1'
        return ["student_admission_no","subject_name","status_name","attendance_type","class_timing_name","batch_name","reason","date"] 
      else
        return ["student_admission_no","subject_name","class_timing_name","batch_name","reason","date"]
      end
    end
  end
  
  
  def daily_wise_csv_header_order
    config_enable = Configuration.get_config_value('CustomAttendanceType') || "0" 
    if Configuration.enabled_roll_number?
      if config_enable == '1'
        return ["student_admission_no","roll_number","status_name","attendance_type", "forenoon","afternoon","date","batch_name","reason"]
      else
        return ["student_admission_no","roll_number", "forenoon","afternoon","date","batch_name","reason"]
      end
    else
      if config_enable == '1'
        return ["student_admission_no","status_name","attendance_type","forenoon","afternoon","date","batch_name","reason"]
      else
        return ["student_admission_no", "forenoon","afternoon","date","batch_name","reason"]
      end
    end
  end

  def filter_records # only refund finance transactions
    trans_ids = @finance_transactions.map {|x| x.id if x.category.name == "Refund" }.compact
    if trans_ids.present?
      exclude_ids = FeeRefund.all(:conditions => ["fa.is_deleted = true AND finance_transaction_id IN (?)", trans_ids],
        :joins => "INNER JOIN finance_fees ff ON ff.id = fee_refunds.finance_fee_id
                                         INNER JOIN finance_fee_collections ffc ON ffc.id = ff.fee_collection_id
                                         INNER JOIN fee_accounts fa On fa.id = ffc.fee_account_id").
        map(&:finance_transaction_id)
      @finance_transactions = @finance_transactions.reject { |x| exclude_ids.include?(x.id) } if (exclude_ids && trans_ids).present?
    end
  end

  def csv_data_export
    if check_database
      @file = open(@export_file_str,'w')
      @file << 'No data to show'
      update_attributes(:status => "Success")
      @file.close
    else
      
      i = 0
      config = Configuration.find_by_config_key("StudentAttendanceType").config_value
      if export_structure.model_name == "attendance" and  config == "SubjectWise"
        es = "SubjectLeave" 
      else
        es = export_structure.model_name 
      end
     
      es.camelize.constantize.send(export_structure.make_query.first,export_structure.make_query.second.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}) do |block_datas|
        instance_variable_set("@" + export_structure.model_name.pluralize,block_datas)
        filter_records if es == 'finance_transaction'
        next unless eval("@" + export_structure.model_name.pluralize).present?
        @xml = FedenaDataExport::Parser.new
        template_file = get_template
        template_file.result(get_binding)
        
        parent_key = @xml.result_hash.keys.first
        logger = Logger.new("#{RAILS_ROOT}/log/delayed_job.log")
        sub_parent_key = @xml.result_hash[parent_key].keys.first if @xml.result_hash[parent_key].length == 1
        sub_parent_key = @xml.result_hash[parent_key].first.keys.first if @xml.result_hash[parent_key].length > 1
        final_headers_s = @xml.get_headers(@xml.result_hash[parent_key].length == 1 ? (@xml.result_hash[parent_key]) : (@xml.result_hash[parent_key].first), sub_parent_key)
        final_headers = final_headers_s.map(&:to_s)
        headers = final_headers.map(&:humanize)
       
        default_headers = export_structure.csv_header_order.map(&:humanize)
        default_headers = subject_leave_csv_header_order.map(&:humanize) if es == "SubjectLeave"
        default_headers = daily_wise_csv_header_order.map(&:humanize)  if es == "attendance" 
        check_headers = export_structure.csv_header_order.map(&:to_sym)
        check_headers = subject_leave_csv_header_order.map(&:to_sym) if es == "SubjectLeave"
        check_headers = daily_wise_csv_header_order.map(&:to_sym) if es == "attendance" 
        if es == "student"
          default_headers.delete("Roll number") unless Configuration.enabled_roll_number?
        end
        if @xml.result_hash[parent_key].is_a?(Hash)
          FedenaDataExport::Parser.make_array(@xml.result_hash)
        end

        if i == 0
          @file = FasterCSV.open(@export_file_str, "w") do |csv|
            csv << default_headers
          end
        end
        
        @file = FasterCSV.open(@export_file_str, "a") do |csv|
          @xml.result_hash[parent_key].each do |hash|
            values = Array.new
            hash.each do |key,value|
              check_headers.each do |default_header|
                
                value.each do |sub_key,sub_value|
                  if default_header == sub_key
                    unless sub_value.is_a? Hash
                      values << sub_value
                    else
                      
                      unless sub_key == :employee_salary_details
                        values.push(make_hash_table(sub_value,sub_key))
                      else
                        values.push(make_hash_salary_structure_table(sub_value))
                      end
                      
                    end
                    break;
                  end
                end
              end
              
            end
            csv << values
          end
          
        end
        
        
        i += 1
        break if export_structure.model_name == "configuration"
      end
    end
  end
  
  
  
  
  
  
  def make_hash_salary_structure_table(table_data)
    new_table =[]
    unless table_data.blank?
      earnings, deductions = table_data[:earning], table_data[:deduction]
      new_table << "Payroll group - #{table_data[:payroll_group]}\n"
      new_table << "Gross salary - #{table_data[:gross_salary]}\n"
      new_table << "Earnings\n"
      arr= earnings.nil? ? ([]) : earnings[:payroll_category].zip(earnings[:amount]).map{|a| a.join('-')}
      arr.each do |a|
        new_table << "#{a}\n"
      end
      new_table << "Total earnings - #{table_data[:total_earning]}\n"
      new_table << "Deductions\n"
      arr= deductions.nil? ? ([]) : deductions[:payroll_category].zip(deductions[:amount]).map{|a| a.join('-')}
      arr.each do |a|
        new_table << "#{a}\n"
      end
      new_table << "Total deductions - #{table_data[:total_deduction]}\n"
      new_table << "Net pay - #{table_data[:net_pay]}"
    else
      
      new_table << "Payroll group - \n"
      new_table << "Gross salary - \n"
      new_table << "Earnings\n"
      new_table << "Total earnings - \n"
      new_table << "Deductions\n"
      new_table << "Total deductions - \n"
      new_table << "Net pay - "
    end
    new_table
  end
  
  def make_hash_table(table_data,key)
    hash_priority = export_structure.model_name.camelize.constantize.get_hash_priority
    table_headers = hash_priority[key]
    new_table = []
    new_table << "#{(table_headers.map(&:to_s).map(&:humanize)).join(',')}\n"
    
    extracted_data = table_data[table_data.keys.first]
    values = []
    table_headers.each {|x| extracted_data.nil? ? (values << []) : (values <<  extracted_data[x])}
    value_results = values.transpose.map {|x| x.join(',')}
    value_results.each do |data|
      new_table << "#{data}\n"
    end
    
    new_table
  end
  
  
  
  
  

  

  

  def get_binding
    binding
  end
end