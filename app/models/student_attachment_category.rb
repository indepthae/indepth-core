class StudentAttachmentCategory < ActiveRecord::Base
  belongs_to :creator, :class_name => 'User'
  has_many :student_attachment_records, :before_remove => :destroy_student_attachments
  has_many :student_attachments, :through => :student_attachment_records, :dependent => :destroy
  
  validates_presence_of :attachment_category_name
  validates_uniqueness_of :attachment_category_name, :case_sensitive => false

  validate :verify_name
  attr_accessor :registered
  
  def verify_name
    if self.attachment_category_name.present?
      errors.add(:attachment_category_name, :reserved) if self.attachment_category_name.downcase == t('student_document_categories.default_category').downcase or self.attachment_category_name.downcase == t('student_document_categories.registered_default_category').downcase
    end    
  end
  
  def has_documents? # checks if category has documents added to it 
    return student_attachments.last.present?
  end
  
  def category_id
    self.new_record? ? (self.registered ? 'registered' : "nil") : self.id
  end
    
  def perform_destroy deletion_choice, category    
    move_to_category = StudentAttachmentCategory.fetch(category) #if category.present?
    unless deletion_choice.present?
      errors.add_to_base(:delete_option_missing)       
    else
      case deletion_choice
      when "0" # 0 destroy category & all documents under it
        self.destroy
        #      when "1" # 1 destroy category by moving documents to default category
        #        StudentAttachmentRecord.delete_all({:student_attachment_category_id => self.id })
        #        self.destroy
      when "2" # 2 destroy category and move documents to specific chosen category
        # add errors unless move_to_category.present?        
        if category.present?
          student_attachment_ids = StudentAttachmentRecord.all(:conditions => {:student_attachment_category_id => category_id}, :select => "student_attachment_id").map(&:student_attachment_id)        
          move_to_category.new_record? ? StudentAttachmentRecord.delete_all({:student_attachment_category_id => self.id }) : StudentAttachmentRecord.update_all({:student_attachment_category_id => category }, {:student_attachment_category_id => self.id })#errors.add_to_base(:invalid_delete_option)              
          StudentAttachment.update_all({:is_registered => true}, {:id => student_attachment_ids}) if move_to_category.category_id == 'registered' and student_attachment_ids.present?
          self.destroy
        else
          errors.add_to_base(:category_to_move_to_not_selected)          
        end
      else
        errors.add_to_base(:invalid_delete_option)
      end    
    end    
  end
    
  def self.default is_registered=false      
    category =self.new({:attachment_category_name => t("student_document_categories.#{ is_registered ? 'registered_' : ''}default_category") })
    category.registered = is_registered
    category
  end
  
  def self.fetch(category_id)    
    if category_id.nil? or category_id == 'nil'
      category = StudentAttachmentCategory.default
    elsif category_id.present? 
      category = (category_id != 'nil') ? (category_id == 'registered' ? StudentAttachmentCategory.default(true) : StudentAttachmentCategory.find_by_id(category_id)) : StudentAttachmentCategory.default
    end
    category
  end
        
  def self.fetch_all(args=nil)    
    exclude_ids= args.present? && args['exclude_ids'].present? ? args['exclude_ids'] : ''
    categories = []
    categories << StudentAttachmentCategory.default unless exclude_ids.include?('nil')
    categories << StudentAttachmentCategory.default(true) unless exclude_ids.include?('registered')
    exclude_ids.delete 'nil' if exclude_ids.include?('nil')
    exclude_ids.delete 'registered' if exclude_ids.include?('registered')
    exclude_conditions = exclude_ids.present? ? ["id not in (?)",exclude_ids] : []
    categories += StudentAttachmentCategory.all(:conditions => exclude_conditions, :order => "attachment_category_name")
  end
end
