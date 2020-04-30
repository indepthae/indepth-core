class ReportQuery < ActiveRecord::Base
  belongs_to :report
  attr_reader :date_query
  attr_accessor :field_name

  begin
    columns_hash['date_query'] = ActiveRecord::ConnectionAdapters::Column.new("date_query", nil, "date")
  rescue Exception => e
    logger.error "[FIXME] #{e} #{__FILE__}:#{__LINE__}"
  end

  def date_query=(date)
    self.query=date.strftime('%Y-%m-%d').to_s
  end
  serialize :query
  def values_for_associations
    if column_type == :association
      parent_model_name = table_name
      parent_model = Kernel.const_get(parent_model_name.to_sym)
      assoc_object=parent_model.reflect_on_association(column_name.to_sym).klass
      if assoc_object.respond_to? :report_data
        return assoc_object.report_data
      else
        return assoc_object.all
      end
    end
  end

  def criteria_to_s
    {'gte'=>'Greater than',
      'lte'=>'Less than',
      'like'=>'Like',
      'begins_with'=>'Begins with',
      'equals'=> 'Equals',
      'in' => 'In',
      ''=>''
    }[criteria]
  end
  def searchlogic_criteria
    {
      'gte'=>'gte',
      'lte'=>'lte',
      'like'=>'like',
      'begins_with'=>'begins_with',
      'equals'=> 'equals',
      'in' => 'in',
      ''=>''
    }[criteria]
  end

  def criteria_to_sql
    {'gte'=>'>=',
      'lte'=>'<=',
      'like'=>'LIKE',
      'begins_with'=>'LIKE',
      'equals'=> '=',
      'in' => 'IN',
      ''=>''
    }[criteria]
  end

  def query_string
    case column_type
    when 'string'
      self.column_name+"_"+self.criteria
    when 'date'
      self.column_name+"_"+self.criteria
    when 'association'
      self.column_name+"_id_"+self.criteria
    when 'boolean'
      self.column_name+"_"+self.criteria
    when 'integer'
      self.column_name+"_"+self.criteria
    end
  end
  def table_name_as_string
    return "#{eval(table_name).table_name}"
  end
  def query_as_string
    if query.is_a? Array
      return "(#{query.join(",")})"
      elseif query.is_a? String
      return "#{query}"
    else
      return query
    end
  end
  def make_query
    if query.is_a? String
      return "#{table_name_as_string}.#{column_name} #{criteria_to_sql} '#{query_as_string}'"
    else
      return "#{table_name_as_string}.#{column_name} #{criteria_to_sql} #{query_as_string}"
    end
  end
  def additional_detail_associated_column
    "#{report.model_object.additional_field_model_foreign_key}"
  end
  def bank_detail_associated_column
    "#{report.model_object.bank_field_model_foreign_key}"
  end
  def make_query_for_additional_field
    ["#{table_name_as_string}.#{additional_detail_associated_column}=#{column_name.to_i} AND #{table_name_as_string}.additional_info #{criteria_to_sql} REPLACE(?, '&dot;', '.')",query_as_string.gsub(".", "&dot;")]
  end
  def make_query_for_bank_field
    ["#{table_name_as_string}.#{bank_detail_associated_column}=#{column_name.to_i} AND #{table_name_as_string}.bank_info #{criteria_to_sql} REPLACE(?, '&dot;', '.')",query_as_string.gsub(".", "&dot;")]
  end
end
