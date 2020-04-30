class Report < ActiveRecord::Base
  
  has_many :report_queries,:dependent => :destroy
  has_many :report_columns,:dependent => :destroy

  accepts_nested_attributes_for  :report_columns
  accepts_nested_attributes_for :report_queries,
    :reject_if => proc { |attributes|
    attributes['query'].blank? and (attributes['date_query(1i)'].blank? or
        attributes['date_query(2i)'].blank? or
        attributes['date_query(3i)'].blank?)
  }

  validates_presence_of :name, :report_columns

  def after_initialize
    unless model_object.nil?
      model_object.extend JoinScope
      model_object.extend AdditionalFieldScope
    end
  end
  
  def search_param
    sp={}
    self.report_queries.each do |rq|
      sp[rq.query_string]= rq.query unless ['join','additional','bank'].include? rq.column_type
    end
    sp[:join_params]=join_params
    sp[:additional_field_params]=additional_field_params
    sp[:bank_field_params]=bank_field_params if self.model == 'Employee'
    sp
  end
  
  def join_params
    jp={}
    cond={}
    join_queries=report_queries.group_by(&:column_type)['join']
    unless join_queries.blank?
      join_queries = join_queries.group_by(&:table_name)
      jp[:joins] = join_queries.keys.collect{|k| eval(k).table_name.singularize.to_sym}
      join_queries.each do |k,rqs|
        cond[k]=[]
        rqs.each do |rq|
          cond[k] << rq.make_query
        end
      end
      q_str=[]
      cond.values.each do |str|
        q_str << "(#{str.join(" OR ")})"
      end
      jp[:conditions]=[q_str.join(" AND ")]
    end
    jp
  end

  def additional_field_params
    ap={}
    cond={}
    additional_field_queries = report_queries.group_by(&:column_type)['additional']
    unless additional_field_queries.blank?
      additional_field_queries = additional_field_queries.group_by(&:table_name)
      ap[:joins] = additional_field_queries.keys.collect{|k| eval(k).table_name.to_sym}
      additional_field_queries.each do |k,rqs|
        cond[k]=[]
        rqs.each do |rq|
          cond[k] << rq.make_query_for_additional_field
        end
      end
      query_strings=[]
      query_values = []
      cond.values.each do |str|
        queries = []
        str.each{|s| queries << "(#{s.first})"; query_values << s[1..-1]}
        query_strings << "(#{queries.join(" OR ")})"
      end
      ap[:conditions]=[query_strings.join(" OR ")] + query_values.flatten
    end
    ap
  end
  
  def bank_field_params
    bp={}
    cond={}
    bank_field_queries = report_queries.group_by(&:column_type)['bank']
    unless bank_field_queries.blank?
      bank_field_queries = bank_field_queries.group_by(&:table_name)
      bp[:joins] = bank_field_queries.keys.collect{|k| eval(k).table_name.to_sym}
      bank_field_queries.each do |k,rqs|
        cond[k]=[]
        rqs.each do |rq|
          cond[k] << rq.make_query_for_bank_field
        end
      end
      query_strings=[]
      query_values = []
      cond.values.each do |str|
        queries = []
        str.each{|s| queries << "(#{s.first})"; query_values << s[1..-1]}
        query_strings << "(#{queries.join(" OR ")})"
      end
      bp[:conditions]=[query_strings.join(" OR ")] + query_values.flatten
    end
    bp
  end
 
  def include_param
    ip=[]
    model_name = Kernel.const_get(self.model)
    self.report_columns.each do |rc|
      model_name.fields_to_search[:association].each do |as|
        case as
        when Symbol
          (ip << as) if rc.method.include? as.to_s
        when Hash
          (ip << as) if (as.keys+as.values).include? rc.method.to_sym
        end
      end
      (ip << rc.association_method.to_sym) if rc.association_method.present?
      (ip << self.model_object.additional_detail_table) if rc.method.to_s.include?("_additional_fields_")
    end
    ip.uniq
  end
  
  def having_param
    hav_param = {}
    additional_field_queries = report_queries.group_by(&:column_type)['additional']
    table_name = Kernel.const_get(model.to_sym).table_name
    hav_param[:having] = "COUNT(#{table_name}.id) = #{additional_field_queries.count}" unless additional_field_queries.blank?
    hav_param
  end
  
  def to_csv
    csv = Array.new
    cols = [t('sl_no')]
    self.report_columns.each{|rc| cols << rc.title}
    csv << cols
    table_name = Kernel.const_get(model.to_sym).table_name
    query_parameters = {:include=>self.include_param, :group => "#{table_name}.id"}.merge(self.having_param)
    search_results = model_object.report_search(self.search_param).all(query_parameters)
    search_results.each_with_index do |obj,serial_no|
      fields_hash = {}
      obj.class.columns_hash.collect{|x,y| fields_hash[x]=y.type}
      cols = []
      cols << (serial_no + 1)
      self.report_columns.each do |col|
        unless col.association_method.present?
          if (obj.class.name == "Student" and (col.method.to_s == "immediate_contact_relation" or col.method.to_s == "parent_relation"))
            value = obj.immediate_contact_translated_relation if col.method.to_s == "immediate_contact_relation"
            value = obj.parent_translated_relation if col.method.to_s == "parent_relation"
          else
            value = obj.send(col.method)
          end
        else
          value = ""
          obj.send(col.association_method).each_with_index do |asso_val, i|
            value_types = {}
            asso_val.class.columns_hash.collect{|x,y| value_types[x]=y.type}
            value += "\n" if i > 0
            if (col.association_method == "guardians" and col.method == "relation")
              value += "#{convert_value(asso_val.send("translated_relation"), value_types[col.method])}"
            else
              value += "#{convert_value(asso_val.send(col.method), value_types[col.method])}"
            end
          end
        end
        cols << convert_value(value, fields_hash[col.method])
      end
      csv << cols
    end
    return csv
  end

  def self.generate_custom_csv_file(parameters)
    report = Report.find parameters[:id]
    report_columns = report.report_columns
    report_columns.delete_if{|rc| (rc.association_method.nil? or rc.association_method.blank?) and !((report.model_object.instance_methods+report.model_object.column_names).include?(rc.method))}
    report_columns.delete_if{|rc| rc.association_method.present? and report.model_object.instance_methods.include? rc.association_method and !((rc.association_method_object.instance_methods+rc.association_method_object.column_names).include?(rc.method))}
    csv = report.to_csv
    return csv
    # filename = "#{report.name}-#{Time.now.to_date.to_s}.csv"
    # send_data(csv, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end

  def convert_value(value, type)
    case type
    when :date
      format_date(value)
    when :datetime
      format_date(value,:format=>:short_date)
    when :time
      format_date(value,:format=>:time)
    else
      value
    end
  end
  
  def model_object
    Kernel.const_get(self.model) unless self.model.nil?
  end
end
  
