class MessageTemplateContent < ActiveRecord::Base
  belongs_to :message_template

  def replace_automated_keys(automated_set,values)
    if check_valid_automated_key(automated_set, values)
      @replaced_content = self.content.clone
      values.each do |key, value|
        
        replace_keys(key,value)
      end
    end
    return @replaced_content
  end
  
  def check_valid_automated_key(automated_set,values)
    keys_set = MessageTemplate::TEMPLATE_KEYS[:automated][automated_set]
    if !keys_set.present?
      return false
    end
    values.keys.each do |key|
      return false if !keys_set[key].present? 
    end
    return true
  end
  
  def replace_keys(key,value)
    full_key = "{{#{key.to_s}}}"
    @replaced_content.gsub!(full_key, value)
  end
end
