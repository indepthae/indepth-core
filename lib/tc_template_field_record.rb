# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class TcTemplateFieldRecord
  attr_accessor :field_format_value, :field_type, :field_format, :priority, :value, :is_enabled, :text_size, :text_color, :random, :additional_field, :is_mandatory, :is_in_figures_enabled, :is_in_words_enabled
  
  def initialize(hash = {})
    @field_type = hash[:field_type] || nil
    @field_format = hash[:field_format] || nil
    @field_format_value = hash[:field_format_value] || nil
    @priority = hash[:priority] || nil
    @value = hash[:value] || nil
    @is_enabled = hash[:is_enabled] || nil
    @text_size = hash[:text_size] || nil
    @text_color = hash[:text_color]
    @additional_field = []
    @random = hash[:random] || nil
    @is_mandatory = hash[:is_mandatory] || nil
    @is_in_figures_enabled = hash[:is_in_figures_enabled]
    @is_in_words_enabled = hash[:is_in_words_enabled]
  end
  
  def additional_field_update(data)
    data.each_pair do |rand, field|
      @additional_field << TcTemplateFieldRecord.new(:value=>field["text"].strip, :text_size=>field["text_size"].strip, :text_color=>field["text_color"].strip, :priority=> rand)
    end
  end
  
  def signature_field_update(data)
    data.each_pair do |prio, field|
      @additional_field << TcTemplateFieldRecord.new(:value=>field["value"].strip, :priority=>prio, :field_type=>field["type"])
    end
  end
  
  def ==(other_obj)
    (field_type == other_obj.field_type)&&
      (field_format == other_obj.field_format)&&
      (field_format_value == other_obj.field_format_value)&&
      (priority == other_obj.priority)&&
      (value == other_obj.value)&&
      (is_enabled == other_obj.is_enabled)&&
      (text_size == other_obj.text_size)&&
      (text_color == other_obj.text_color)&&
      (random == other_obj.random)
  end

	 def multiple_field_update(field_type,field_format,field_format_value,additional_fields,is_mandatory)
    @field_type = field_type
    @field_format = field_format
    @field_format_value = field_format_value
    @is_mandatory = is_mandatory
    additional_fields.each_pair do |key,value|
      @additional_field << TcTemplateFieldRecord.new(:value=> value)
    end
  end
  
   def compare_student_details(field,field_info)
     if field.field_info.field_type == field_info.field_type and field.field_info.field_format == field_info.field_format and field.field_info.field_format_value == field_info.field_format_value and field.field_info.is_in_words_enabled == field_info.is_in_words_enabled and field.field_info.is_in_figures_enabled == field_info.is_in_figures_enabled and field.field_info.value == field_info.value
       flag = 1
       if field.field_info.field_format == "select_box"
         if field.field_info.additional_field.size == field_info.additional_field.size
           field.field_info.additional_field.collect{|value| value.value.each do |key|
               flag = 0
               field_info.additional_field.collect{|hash_value| hash_value.value.each do |hash_key|
                   if key == hash_key
                     flag =1
                   end                
                 end}
               break if flag == 0             
             end}
         else
           flag = 0
         end
       end
     else
       flag = 0
     end
     return flag
   end
   
   def compare_header_details(field,field_info)
     if field.field_info.value == field_info.value and field.field_info.is_enabled == field_info.is_enabled
       flag = true
     else
       flag = false
     end
     return flag
   end
end
