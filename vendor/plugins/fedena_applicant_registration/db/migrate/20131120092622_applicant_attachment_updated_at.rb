class ApplicantAttachmentUpdatedAt < ActiveRecord::Migration
  def self.up
    column_create = {"applicants"=>"photo", "applicant_addl_attachments"=>"attachment"}
    column_create.each do |table_name,attachment_name|
      attachment_update_at = attachment_name + "_updated_at"
      add_column table_name.to_sym, attachment_update_at.to_sym, :datetime
      sql_update = "update #{table_name} set #{attachment_update_at}=updated_at"
      ActiveRecord::Base.connection.execute(sql_update)
    end
  end

  def self.down
  end
end
