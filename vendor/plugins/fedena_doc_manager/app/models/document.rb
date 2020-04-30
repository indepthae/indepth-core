class Document < ActiveRecord::Base

  belongs_to :folder
  belongs_to :user                                  #for created user information
  has_many :document_users
  has_many :users, :through => :document_users      #for marking documents favorite
  has_and_belongs_to_many :linked_users, :class_name => 'User'
  has_attached_file :attachment,
    :path => "uploads/:class/:user_id/:id_partition/:basename.:extension",
    :url => "/documents/:id/download",
    :max_file_size => 5242880,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types => []

  validates_attachment_content_type :attachment,
    :content_type => [ 'image/png','image/jpg','image/jpeg','image/gif','image/bmp','application/pdf',
    'application/powerpoint','application/mspowerpoint','application/vnd.ms-powerpoint',
    'application/x-mspowerpoint','application/msword','application/mspowerpoint',
    'application/vnd.ms-powerpoint','application/excel','application/vnd.ms-excel',
    'application/x-excel','application/x-msexcel','application/rtf','application/x-rtf',
    'text/richtext','text/plain','application/wordperfect','application/x-wpwin',
    'text/tab-separated-values','text/csv','application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.openxmlformats-officedocument.presentationml.slideshow','application/vnd.oasis.opendocument.text',
    'application/vnd.oasis.opendocument.spreadsheet','image/svg+xml','application/vnd.ms-works','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/wpd','application/wordperf','application/vnd.openxmlformats-officedocument.presentationml.presentation'
  ],:message=>'is invalid'

  validates_attachment_size :attachment, :less_than => 5242880,\
    :message=>'must be less than 5 MB.',:if=> Proc.new { |p| p.attachment_file_name_changed? }
  validates_presence_of :name, :user_id, :attachment
  validate :file_present
  before_save :update_favorite

  named_scope :privilege_allowed, lambda {|user| {:conditions => [user.admin => true, :user.privileges.map(&:name).include => "DocumentManager"]}}
  named_scope :no_folder, :conditions => {:folder_id=> nil}
  named_scope :is_favorite, :conditions => {:is_favorite => true}

  def toggle_favorite
    self.is_favorite = self.is_favorite.nil? ? true : self.is_favorite? ? false : true
    self.save
    self.is_favorite ? t('documents.flash4') : t('documents.flash5')
  end

  def update_favorite
    self.is_favorite == false if self.is_favorite == nil
  end

  def favorite_modify(current_user)
    if self.user_id == current_user.id
      self.toggle_favorite
      flash_notice = self.is_favorite ? t('doc_managers.flash7') : t('doc_managers.flash8')
    else
      DocumentUser.find_by_user_id_and_document_id(current_user.id,self.id).toggle_favorite
      flash_notice = DocumentUser.find_by_user_id_and_document_id(current_user.id,self.id).is_favorite ? t('doc_managers.flash7') : t('doc_managers.flash8')
    end
    flash_notice
  end

  def file_present
    if self.name.present?
      unless self.attachment.present?
        errors.add_to_base(:file_field_blank)
      end
    end
  end

  def self.search_docs(current_user,query)
    documents = []
    documents << current_user.child_documents.find(:all,:conditions => ["name LIKE ? OR attachment_file_name LIKE ? ","%#{query}%","%#{query}%"]) unless query == ''
    documents << current_user.documents.find(:all,:conditions => ["name LIKE ?","%#{query}%"]) unless query == ''
    documents.flatten.compact
    documents.flatten.sort_by {|x| x.name}
  end

  def self.delete_checked(document_ids,current_user)
    flash_notice = nil
    documents = Document.find_all_by_id(document_ids)
    documents.each do |d|
      if d.user_id == current_user.id
        d.destroy
        flash_notice = t('documents.flash10')
      elsif d.folder.class == PrivilegedFolder
        d.destroy
        flash_notice = t('documents.flash10')
      elsif d.folder.class == ShareableFolder or d.user_id != current_user.id
        d.user_ids = d.user_ids.delete_if {|x| x == current_user.id}
        flash_notice = t('documents.flash8')
      end
    end
    flash_notice
  end

  def destroy_document(current_user)
    if self.user_id == current_user.id
      self.destroy
      flash_notice = t('documents.flash3')
    elsif self.folder.present?
      case self.folder.class.to_s
      when "ShareableFolder"
        flash_notice = t('doc_managers.flash11')
      when "PrivilegedFolder"
        self.user_ids = []
        self.destroy
        flash_notice = t('documents.flash3')
      when "AssignableFolder"
        self.destroy
        flash_notice = t('documents.flash3')
      end
    else
      self.user_ids = self.user_ids.delete_if {|x| x == current_user.id}
      flash_notice = t('documents.flash8')
    end
    flash_notice
  end

  def check_public_true(cur_val)
    if cur_val == "private"
      if self.user_ids.present?
        return true
      else
        return false
      end
    else
      if self.user_ids.present?
        return false
      else
        return true
      end
    end
  end
  def is_public?
    self.user_ids.blank? && self.folder.type=="PrivilegedFolder"
  end
  def self.check_and_save(documents,current_user,members)
    error = false
    count = 0
    document = nil
    if documents.present?
      documents.each_pair do |k,v|
        document = current_user.child_documents.build(v)
        unless v[:name].present? == v[:attachment].present? and v[:name].present?
          error = true
          document.errors.add_to_base(:document_name_blank) unless v[:name].present?
          document.errors.add_to_base(:file_field_blank) unless v[:attachment].present?
          break
        else
          file_size = v[:attachment].size rescue false
          unless file_size==false
            if file_size > Document.new.attachment.instance_variable_get('@max_file_size')
              error = true
              document.errors.add_to_base(t('documents.doc_size'))
              break
            end
          end
        end
        count = count + 1 if v[:attachment].present?
      end
    else
      document = current_user.documents.build
    end
    if count.zero? and document.new_record?
      document.errors.add_to_base(:no_document)
      error = true
    end
    unless (count.zero? && error) or (error)
      documents.each_pair do |k,v|
        document = current_user.child_documents.new(v)
        if document.save
          document.user_ids= members.split(",").reject{|a| a.strip.blank?}.collect{|s| s.to_i}
        end
      end
    end
    return document
  end

  def is_allowed current_user
    return true if (current_user.admin? or current_user.privileges.map(&:name).include? "DocumentManager")                           #admin/privileged_user
    return true if (self.folder.class.to_s == "PrivilegedFolder" and (self.users.empty? or self.users.include? current_user)) #privileged_folder public and private doc
    return true if (self.user_id == current_user.id)                                                                          #any creator doc
    return true if (self.folder.class.to_s == "ShareableFolder" and self.folder.users.include? current_user)                  #shared_folder doc
    return true if (self.folder_id == nil and self.users.include? current_user)                                               #shared doc
    false
  end

  Paperclip.interpolates :user_id  do |attachment, style|
    attachment.instance.user_id
  end

end
