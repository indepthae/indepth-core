require 'dispatcher'
module FedenaDocManager
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_doc_manager do
      ::User.instance_eval { include UserExtension }
    end
  end
  
  module UserExtension
    def self.included(base)
      base.instance_eval do
        has_many :child_documents,:class_name => 'Document',:dependent=>:destroy
        has_many :documents, :through=>:document_users#, :dependent =>:destroy
        has_many :document_users, :dependent=>:destroy
        has_and_belongs_to_many :docs, :class_name => 'Document'

        has_many :folders,:class_name => 'ShareableFolder',:dependent=>:destroy
        has_many :privileged_folders
        has_many :assignable_folders
        has_many :shareable_folders, :through=> :shareable_folder_users#, :dependent=> :destroy
        has_many :shareable_folder_users
        has_and_belongs_to_many :uploadable_privileged_folders, :class_name =>'PrivilegedFolder'
      end

      base.class_eval do
        def document_list (action)
          case action
          when 'my_docs'
            [{:shareable_folder=>{:order=>"name",:conditions=>{:user_id=>self.id}}}, {:document=>{:order=>"name",:conditions=>{:user_id=>self.id,:folder_id=>nil}}}]
          when 'shared_docs'
            [{:shareable_folder=>{:order=>"name",:search_options=>{:shareable_folder_users_user_id_is => self.id}}}, {:document=>{:order=>"name",:search_options=>{:document_users_user_id_is => self.id,:folder_id => nil}}}]
          when 'recent_docs'
            [{:shareable_folder=>{:order=> "updated_at DESC", :select=>"folders.*",:group=>"folders.id",:joins=>"left outer join shareable_folder_users on folders.id = shareable_folder_users.shareable_folder_id",:conditions=>["shareable_folder_users.user_id=? or folders.user_id=?",self.id,self.id]}},{:document=>{:order=> "updated_at DESC",:select=>"documents.*",:joins=>"left outer join document_users on documents.id = document_users.document_id",:group=>"documents.id",:conditions=>["document_users.user_id=? or documents.user_id=?",self.id,self.id]}}]
          when 'favorite_docs'
            [{:shareable_folder=>{:order=> "name",:select=>"folders.*",:group=>"folders.id",:joins=>"left outer join shareable_folder_users on folders.id = shareable_folder_users.shareable_folder_id",:conditions=>["shareable_folder_users.user_id=? and shareable_folder_users.is_favorite=? or folders.user_id=? and folders.is_favorite=?",self.id,true,self.id,true]}},{:document=>{:select=>"documents.*",:joins=>"left outer join document_users on documents.id = document_users.document_id",:group=>"documents.id",:order=>"name",:conditions=>["document_users.user_id=? and document_users.is_favorite=? or documents.user_id=? and documents.is_favorite=?",self.id,true,self.id,true]}}]
#            [{:shareable_folder=>{:order=>"name",:conditions=>{:user_id=>self.id, :is_favorite=> true}}}, {:shareable_folder=>{:order=>"name",:search_options=>{:shareable_folder_users_is_favorite_is=>true,:shareable_folder_users_user_id_is => self.id}}}, {:document=>{:order=>"name",:conditions => {:user_id => self.id, :is_favorite=>true}}}]
          end
        end

        def folder_list (action)
          folders = []
          case action
          when 'privileged_docs'
            if self.admin? or self.privileges.map(&:name).include?("DocumentManager")
              folders << PrivilegedFolder.all
            else
              folders << self.uploadable_privileged_folders
              folders << self.privileged_folders
              folders << Folder.all(:joins => 'INNER JOIN documents AS d ON d.folder_id = folders.id LEFT OUTER JOIN document_users du on du.document_id = d.id',:select=>"folders.*,du.document_id, du.user_id",:conditions => "folders.type = 'PrivilegedFolder' AND (du.user_id IS NULL or du.user_id = #{self.id})", :group => "folders.id", :order =>"name")
            end
          when 'user_docs'
            folders << AssignableFolder.all
          end
          return folders.flatten.uniq.sort_by {|x| x.name.downcase }
        end
      end
    end
  end
end