class IdCardTemplate < ActiveRecord::Base
  xss_terminate

  named_scope :student_templates, {:conditions => {:user_type => 1}}
  named_scope :employee_templates, {:conditions => {:user_type => 2}}
  named_scope :parent_templates, {:conditions => {:user_type => 3}}

  belongs_to :front_template, :class_name => 'BaseTemplate', :foreign_key=> :front_template_id, :dependent=>:destroy
  belongs_to :back_template, :class_name => 'BaseTemplate', :foreign_key=> :back_template_id, :dependent=>:destroy
  has_many :template_custom_fields, :as => :corresponding_template, :dependent=>:destroy
  has_many :generated_id_cards, :dependent=>:destroy
  has_many :bulk_generated_id_cards, :dependent=>:destroy

  accepts_nested_attributes_for :front_template, :back_template 
  accepts_nested_attributes_for :template_custom_fields,  :allow_destroy => true


  validates_presence_of :name, :user_type, :template_resolutions_id, :include_back
  validates_uniqueness_of :name, :case_sensitive => false
  validates_length_of :name, :maximum => 50
  before_validation :name_space_removal, :copy_user_type_to_base_template, :include_back_check, :background_image_removal, :duplicate_barcode_property_for_back_template
  validate :check_if_generated_id_cards_present
  before_destroy :check_dependencies
  attr_accessor :destroy_front_background_image, :destroy_back_background_image, :allow_edit
  

  HUMANIZED_ATTRIBUTES = {
    :name => "#{t('id_card_name_heading')}",
    :user_type => "#{t('applicable_user_type')}",
    :include_back => "#{t('back_template')}" 
  }

  def self.human_attribute_name(attr)
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
  

  VALID_IMAGE_TYPES = ['image/gif', 'image/png','image/jpeg', 'image/jpg']

  has_attached_file :front_background_image,
    :styles => {
    :thumb=> "300x300#"},
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
    :url => "/id_card_templates/download_image/:id?style=:style&side=front",
    :reject_if => proc { |attributes| attributes.present? },
    :max_file_size => 5242880,
    :permitted_file_types =>VALID_IMAGE_TYPES,
    :whiny=>false,
    :download=>false

    validates_attachment_content_type :front_background_image, :content_type =>VALID_IMAGE_TYPES,:message=>'Image can only be GIF, PNG, JPG',:if=> Proc.new { |p| !p.front_background_image_file_name.blank? }
    validates_attachment_size :front_background_image, :less_than => 5242880,\
    :message=>:must_be_less_than_5_mb, :if=> Proc.new { |p| p.front_background_image_file_name_changed? }

    has_attached_file :back_background_image,
      :styles => {
      :thumb=> "300x300#"},
      :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
      :url => "/id_card_templates/download_image/:id?style=:style&side=back",
      :reject_if => proc { |attributes| attributes.present? },
      :max_file_size => 5242880,
      :permitted_file_types =>VALID_IMAGE_TYPES,
      :whiny=>false,
      :download=>false

      validates_attachment_content_type :back_background_image, :content_type =>VALID_IMAGE_TYPES,:message=>'Image can only be GIF, PNG, JPG',:if=> Proc.new { |p| !p.back_background_image_file_name.blank? }
      validates_attachment_size :back_background_image, :less_than => 5242880,\
      :message=>:must_be_less_than_5_mb, :if=> Proc.new { |p| p.back_background_image_file_name_changed? }

    TEMPLATE_KEYS = {
      :student=>{

      },
      :parent=>{

      },
      :employee=>{

      },
      :common=>{

      }

    }

    TEMPLATE_RESOLUTIONS = {
        1 => {:width=> 54, :height=> 86, :name=>"portrait" },
        2 => {:width=> 86, :height=> 54, :name=>"landscape" }
    }


    def self.without_custom_fields
      IdCardTemplate.all(:include=>[:template_custom_fields]).select{|a| a.template_custom_fields == []}
    end


    def template_resolution
      TEMPLATE_RESOLUTIONS[template_resolutions_id]
    end


    def name_space_removal
      self.name = self.name.split.join(" ")
    end


    def self.get_student_keys
      return TEMPLATE_KEYS[:student].merge(BaseTemplate.get_student_keys)
    end

    def self.get_employee_keys
      return TEMPLATE_KEYS[:employee].merge(BaseTemplate.get_employee_keys)
    end
    
    def self.get_guardian_keys
      return TEMPLATE_KEYS[:parent].merge(BaseTemplate.get_parent_keys)
    end
    
    def self.get_common_keys
      return TEMPLATE_KEYS[:common].merge(BaseTemplate.get_common_keys)
    end
    
    def background_image_removal
      if self.destroy_front_background_image == true || self.destroy_front_background_image == "true"
        self.front_background_image.clear
      end
      if self.destroy_back_background_image == true || self.destroy_back_background_image == "true"
        self.back_background_image.clear
      end
    end

    def copy_user_type_to_base_template
      if front_template.present?
        front_template.template_for = user_type
      end
      if back_template.present?
        back_template.template_for = user_type
      end
    end

    def template_for
      if user_type == 1
        return "Student"
      elsif user_type == 2
        return "Employee"
      elsif user_type == 3
        return "Guardian"
      else
        return "Invalid"
      end
    end


    def include_back_check
      if self.include_back == "no"
        self.back_template.template_data=""
        self.back_background_image.destroy
      end
    end
    
    def check_if_generated_id_cards_present
      if self.generation_done?  && (!self.allow_edit == true)
        errors.add(:base,t('cannot_edit_id_card_template_after_generation'))
      end  
    end
    
    def generation_done?
      return self.generated_id_cards.present? || self.bulk_generated_id_cards.present?
    end
    
    def check_dependencies
      return false if self.generation_done?
    end
    
    def get_templpate_keys
      keys={}
      keys = self.front_template.get_included_template_keys
      keys = keys.merge(self.back_template.get_included_template_keys)
      return keys
    end
    
    
    def get_included_template_keys
      front_keys = self.front_template.get_included_template_keys
      back_keys = {}
      back_keys = self.back_template.get_included_template_keys if self.back_template.present?
      return front_keys.merge(back_keys) 
    end
    
    
    def get_key_names
      key_names={}
      if user_type == 1
        key_names = IdCardTemplate.get_student_keys
      elsif user_type == 2
        key_names = IdCardTemplate.get_employee_keys
      elsif user_type == 3
        key_names = IdCardTemplate.get_guardian_keys
      else 
      end  
      key_names = key_names.merge(IdCardTemplate.get_common_keys)
      return key_names
    end
    
    
    def total_back_id_card_nos(total_id_card_nos)
      total_back_count = nil
      if self.include_back == "common"
        total_back_count = 1
      elsif self.include_back == "no"
        total_back_count = 0
      elsif self.include_back == "unique"
        total_back_count = total_id_card_nos
      else 
      end
      
      return total_back_count
    end
    
    def duplicate_barcode_property_for_back_template
      #note - parent id card doesnt have barcode property so check for barcode property present
      if self.back_template.present? && self.front_template.barcode_property.present?
        self.back_template.barcode_property = self.front_template.barcode_property.clone 
      end
    end

end
