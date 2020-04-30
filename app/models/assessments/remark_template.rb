class RemarkTemplate < ActiveRecord::Base
  
  belongs_to :remark_bank
  
  validates_presence_of :name,:template_body
  
  validate :validate_keys
  
  
  TEMPLATE_KEYS = {
    :student=>{
      :full_name=>'full_name',
      :first_name=>'first_name'
    },
    :additional=>{
      :he_she_up=>'he_she_up',
      :he_she_down=>'he_she_down',
      :him_her_up=>'him_her_up',
      :him_her_down=>'him_her_down',
      :his_her_up=>'his_her_up',
      :his_her_down=>'his_her_down'
    }
  }
  
  def validate_keys
    keys_from_content = get_key_list(self.template_body)
    keys = keys_as_array
    errors_present = false
    keys_from_content.each do |k| 
      errors_present = true unless keys.include?(k)
    end
    errors.add(:template_body, t('unknown_field_codes')) if errors_present
  end
  
  def get_key_list(content)
    return content.scan /\{\{.+?\}\}/  
  end
  
  def self.get_translated_keys(keys)
    new_keys = {}.merge(keys)
    new_keys.each{|key,val| new_keys[key]=t(val)}
    return new_keys
  end


  def self.get_student_keys
    student_keys = RemarkTemplate.get_translated_keys(TEMPLATE_KEYS[:student])
    additional_keys = RemarkTemplate.get_translated_keys(TEMPLATE_KEYS[:additional])
    return student_keys.merge(additional_keys)
  end
  
  def self.get_keys
    keys = TEMPLATE_KEYS[:student].merge(TEMPLATE_KEYS[:additional])
    return keys
  end
  
  def keys_as_array
    key_hash = TEMPLATE_KEYS[:student].merge(TEMPLATE_KEYS[:additional])
    keys = key_hash.collect{|key| "{{#{key.last}}}"}
    keys
  end
  
end
