class PrivilegedFolder < Folder
  has_and_belongs_to_many :users
  belongs_to :user

  def find_priv_docs(current_user)
    priv_documents = []
    if current_user.admin? or current_user.privileges.map(&:name).include? "DocumentManager" or current_user.uploadable_privileged_folders.include? self
      return self.documents
    else
      self.documents.each do |d|
        if d.user_ids.include? current_user.id or d.is_public?
          priv_documents << d
        end
      end
    end
    return priv_documents
  end
end
