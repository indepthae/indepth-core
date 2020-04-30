class CertificateTemplate < ActiveRecord::Base
  xss_terminate

  named_scope :student_templates, {:conditions => {:user_type => 1}}
  named_scope :employee_templates, {:conditions => {:user_type => 2}}
  named_scope :parent_templates, {:conditions => {:user_type => 3}}

  belongs_to :base_template
  has_many :generated_certificates, :dependent=>:destroy
  has_many :template_custom_fields, :as => :corresponding_template, :dependent=>:destroy
  has_many :bulk_generated_certificates, :dependent=>:destroy

  accepts_nested_attributes_for :base_template
  accepts_nested_attributes_for :template_custom_fields, :allow_destroy => true

  validates_presence_of :name, :user_type, :template_resolutions_id
  validates_presence_of :serial_no_prefix, :if => Proc.new {|c| c.manual_serial_no == false }
  validates_uniqueness_of :name, :case_sensitive => false
  validates_uniqueness_of :serial_no_prefix, :if => Proc.new {|c| c.manual_serial_no == false }
  validates_length_of :name, :maximum => 50
  before_validation :name_space_removal, :copy_user_type_to_base_template, :remove_prefix_for_manual, :background_image_removal
  validate :check_if_generated_certificates_present
  before_destroy :check_dependencies
  
  attr_accessor :destroy_background_image, :allow_edit
  


  HUMANIZED_ATTRIBUTES = {
    :name => "#{t('certificate_name_heading')}",
    :user_type => "#{t('applicable_user_type')}",
    :manual_serial_no => "#{t('certificate_serial_no')}",
    :serial_no_prefix => "#{t('serial_no_prefix')}"
  }

 def self.human_attribute_name(attr)
   HUMANIZED_ATTRIBUTES[attr.to_sym] || super
 end


  VALID_IMAGE_TYPES = ['image/gif', 'image/png','image/jpeg', 'image/jpg']

  has_attached_file :background_image,
    :styles => {
    :thumb=> "300x300#"},
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
    :url => "/certificate_templates/download_image/:id?style=:style",
    :reject_if => proc { |attributes| attributes.present? },
    :max_file_size => 5242880,
    :permitted_file_types =>VALID_IMAGE_TYPES,
    :whiny=>false,
    :download=>false

    validates_attachment_content_type :background_image, :content_type =>VALID_IMAGE_TYPES,:message=>'Image can only be GIF, PNG, JPG',:if=> Proc.new { |p| !p.background_image_file_name.blank? }
    validates_attachment_size :background_image, :less_than => 5242880,\
    :message=>:must_be_less_than_5_mb, :if=> Proc.new { |p| p.background_image_file_name_changed? }


    TEMPLATE_KEYS = {
      :student=>{

      },
      :parent=>{

      },
      :employee=>{

      },
      :common=>{
        :serial_no=>'serial_no'
      }

    }


    TEMPLATE_RESOLUTIONS = {
      1=> {:width=>210, :height=>297, :name=>"A4"},
      2=> {:width=>297, :height=>210, :name=>"Landscape"}
    }

    def self.without_custom_fields
      CertificateTemplate.all(:include=>[:template_custom_fields]).select{|a| a.template_custom_fields == []}
    end
    
    def self.bulk_exportable
      CertificateTemplate.all(:conditions=>["manual_serial_no = false"],  :include=>[:template_custom_fields]).select{|a| a.template_custom_fields == []}
    end


    def template_resolution
      TEMPLATE_RESOLUTIONS[template_resolutions_id]
    end

    def remove_prefix_for_manual
      if manual_serial_no.present? && manual_serial_no == true
        self.serial_no_prefix = ""
      end
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
    
    def self.get_common_keys
      common_keys = BaseTemplate.get_translated_keys(TEMPLATE_KEYS[:common])
      return common_keys.merge(BaseTemplate.get_common_keys)
    end

    def copy_user_type_to_base_template
      if base_template.present?
        base_template.template_for = user_type
      end
    end
    
    def background_image_removal
      if self.destroy_background_image == true || self.destroy_background_image == "true"
        self.background_image.clear
      end
    end
    
    def check_if_generated_certificates_present
      if self.generation_done? && (!self.allow_edit == true)
        errors.add(:base,t('cannot_edit_certificate_template_after_generation'))
      end  
    end
    
    def generation_done?
      return self.generated_certificates.present? || self.bulk_generated_certificates.present?
    end
    
    
    def check_dependencies
      return false if self.generation_done?
    end


    def template_for
      if user_type == 1
        return "Student"
      elsif user_type == 2
        return "Employee"
      else
        return "Invalid"
      end
    end
    
    
    def get_key_names
      key_names={}
      if self.user_type == 1
        key_names = CertificateTemplate.get_student_keys
      elsif self.user_type == 2
        key_names = CertificateTemplate.get_employee_keys
      else 
      end 
      key_names = key_names.merge(CertificateTemplate.get_common_keys) 
      return key_names
    end

end
