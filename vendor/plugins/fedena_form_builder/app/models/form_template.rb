class FormTemplate < ActiveRecord::Base
  has_many    :form_fields, :dependent => :destroy
  has_many    :form_field_texts, :dependent => :destroy
  has_many    :form_field_textareas, :dependent => :destroy
  has_many    :form_field_files, :dependent => :destroy
  has_many    :form_field_radios, :dependent => :destroy
  has_many    :form_field_checkboxes, :dependent => :destroy
  has_many    :form_field_horizontal_rules, :dependent => :destroy
  has_many    :form_field_selects, :dependent => :destroy
  has_many    :forms, :dependent => :destroy
  belongs_to  :user
  
  accepts_nested_attributes_for :form_field_texts, :allow_destroy => true
  accepts_nested_attributes_for :form_field_textareas, :allow_destroy => true
  accepts_nested_attributes_for :form_field_files, :allow_destroy => true
  accepts_nested_attributes_for :form_field_radios, :allow_destroy => true
  accepts_nested_attributes_for :form_field_checkboxes, :allow_destroy => true
  accepts_nested_attributes_for :form_field_horizontal_rules, :allow_destroy => true
  accepts_nested_attributes_for :form_field_selects, :allow_destroy => true

  validates_presence_of :name,:message => t('form_templates.template_name_blank')
  named_scope :active, :conditions => {:is_deleted => false}, :order => "updated_at DESC"  

  FieldList = ActiveSupport::OrderedHash.new
  FieldList[:fields] = {}
  FieldConfig.fields.sort.each do |f|
    FieldList[:fields][f.first] = f.second
  end

  def reject_ids(h)
    h.each do |a,b|
      h.delete(a) if a=='id'
      reject_ids(b) if b.is_a? Hash
    end
    return h
  end

  def validate
    unless self.new_record?
      p '9090900'
      unless self.changed.empty?
        p 'no test menot'
        #        self.errors.add_to_base('give new name to save as new template, changes are made to template in use')
        return false
      end
    else
      p 'test me'
      cnt = 0
      cnt += self.form_field_files.size
      cnt += self.form_field_checkboxes.size
      cnt += self.form_field_radios.size
      cnt += self.form_field_texts.size
      cnt += self.form_field_selects.size
      cnt += self.form_field_textareas.size
      errors.add(:base, t('form_templates.field_minimum_one')) if cnt < 1
    end
  end

  def newfield fieldtype
    case fieldtype
    when 'horizontal_rule'
      new_field = self.form_field_horizontal_rules.build
    when 'select'
      new_field = self.form_field_selects.build
    when 'radio'
      new_field = self.form_field_radios.build
    when 'checkbox'
      new_field = self.form_field_checkboxes.build
    when 'text'
      new_field = self.form_field_texts.build
    when 'textarea'
      new_field = self.form_field_textareas.build
    when 'file'
      new_field = self.form_field_files.build
    end
    new_field.set_initial_field_data
    return new_field
  end

  def can_edit_or_delete?
    return (self.forms.empty? ? true : false)
  end

end
