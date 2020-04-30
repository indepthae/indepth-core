class RemarkSetting < ActiveRecord::Base
  serialize :parameters
  has_many :remarks,:foreign_key=>'target_id',:class_name=>"Remark"

  def params_query_string(params)
    params_array = []
    parameters.each_with_index do |param,i|
      params_array << "((p#{i}.param_name = '#{param}') AND (p#{i}.param_value = '#{params[param]}'))"
    end
    params_array.join(" AND ")
  end

  def params_join_string(params)
    join_array = []
    parameters.each_with_index do |param,i|
      join_array << "INNER JOIN remark_parameters AS p#{i} ON remarks.id = p#{i}.remark_id"
    end
    join_array.join(" ")
  end

end
