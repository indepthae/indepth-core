class Folder < ActiveRecord::Base

  has_many :documents, :dependent => :destroy
  validates_presence_of :name
  accepts_nested_attributes_for :documents, :reject_if => lambda { |a| a[:attachment].blank? && a[:name].blank?}, :allow_destroy => true

  named_scope :is_favorite, :conditions => {:is_favorite => true}
  
  def toggle_favorite
    self.is_favorite = self.is_favorite? ? false : true
    self.save
  end
  
  def favorite_modify(current_user)
    if self.user_id == current_user.id
      self.toggle_favorite
      flash_notice = self.is_favorite ? t('doc_managers.flash5') : t('doc_managers.flash6')
    elsif self.type == "ShareableFolder"
      ShareableFolderUser.find_by_user_id_and_shareable_folder_id(current_user.id,self.id).toggle_favorite
      flash_notice = ShareableFolderUser.find_by_user_id_and_shareable_folder_id(current_user.id,self.id).is_favorite ? t('doc_managers.flash5') : t('doc_managers.flash6')
    end
    flash_notice
  end

  def self.search_docs(current_user,query)
    folders = []
    folders << current_user.folders.find(:all,:conditions => ["name LIKE ?","%#{query}%"]) unless query == ''
    folders << current_user.shareable_folders.find(:all,:conditions => ["name LIKE ?","%#{query}%"]) unless query == ''
    if current_user.employee
      if current_user.privileges.map(&:name).include?("DocumentManager")
        folders << PrivilegedFolder.find(:all,:conditions => ["name LIKE ?","%#{query}%"]) unless query == ''
      else
        folders << current_user.privileged_folders.find(:all,:conditions => ["name LIKE ?","%#{query}%"]) unless query == ''
      end 
    elsif current_user.admin
      folders << PrivilegedFolder.find(:all,:conditions => ["name LIKE ?","%#{query}%"]) unless query == ''
    end
    folders << current_user.uploadable_privileged_folders.find(:all,:conditions => ["name LIKE ?","%#{query}%"]) unless query == ''
    folders << Folder.all(:joins => 'INNER JOIN documents AS d ON d.folder_id = folders.id LEFT OUTER JOIN document_users du on du.document_id = d.id',:select=>"folders.*,du.document_id, du.user_id",:conditions => "folders.type = 'PrivilegedFolder' AND folders.name LIKE \"%#{query}%\" AND (du.user_id IS NULL or du.user_id = #{self.id})", :group => "folders.id", :order =>"name")
    folders.delete nil
    folders.flatten.sort_by {|x| x.name }
  end

  def destroy_folder(current_user)
    case self.class.to_s
    when "AssignableFolder"
      documents = Document.find(:all,:conditions=>"folder_id = #{self.id}")
      if documents.blank?
        self.destroy
        flash_notice = t('folders.flash15')
      else
        flash_notice = t('folders.flash17')
      end
    when "PrivilegedFolder"
      self.destroy
      flash_notice = t('folders.flash8')
    when "ShareableFolder"
      if self.user_id == current_user.id
        self.destroy
        flash_notice = t('folders.flash8')
      else
        self.user_ids = self.user_ids.delete_if {|x| x == current_user.id}
        flash_notice = t('folders.flash14')
      end
    else
      self.user_ids = self.user_ids.delete_if {|x| x == current_user.id}
      flash_notice = t('folders.flash14')
    end
  end

  def self.delete_checked(folder_ids,current_user)
    flash_notice = ""
    folders = Folder.find_all_by_id(folder_ids)
    folders.each do |f|
      if f.user_id == current_user.id
        f.destroy
        flash_notice = t('folders.flash13')
      elsif f.class == PrivilegedFolder
        f.destroy if f.user_ids.include? current_user.id
        flash_notice = t('folders.flash13')
      elsif f.class == ShareableFolder
        f.user_ids = f.user_ids.delete_if {|x| x == current_user.id}
        flash_notice = t('folders.flash14')
      elsif f.class == AssignableFolder
        f.destroy if Privilege.find_by_name("DocumentManager").users.include? current_user or current_user.admin
        flash_notice = t('folders.flash13')
      end
    end
    flash_notice
  end
  def delete_allowed(current_user)
    return true if (current_user.admin? or current_user.privileges.map(&:name).include? "DocumentManager")
    return true if (self.user_id == current_user.id)
    return true if (self.class.to_s == "ShareableFolder" and (self.user ==current_user or self.users.include? current_user))
    return true if (self.class.to_s == "PrivilegedFolder" and (self.user == current_user))
    return false
  end
end
