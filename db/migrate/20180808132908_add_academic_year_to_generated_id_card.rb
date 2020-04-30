class AddAcademicYearToGeneratedIdCard < ActiveRecord::Migration
  def self.up
    add_column :generated_id_cards, :batch_id, :integer
  end

  def self.down
    remove_column :generated_id_cards, :batch_id
  end
end
