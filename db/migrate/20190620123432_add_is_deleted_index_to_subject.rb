class AddIsDeletedIndexToSubject < ActiveRecord::Migration
  def self.up
    add_index :subjects, [:is_deleted, :elective_group_id] , :name => 'index_on_elective_active_subject'
  end

  def self.down
    remove_index :subjects,  :name => "index_on_elective_active_subject"
  end
end
