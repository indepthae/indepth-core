class AddWeightToFormFieldOptions < ActiveRecord::Migration
  def self.up
    add_column :form_field_options, :weight, :integer
  end

  def self.down
    remove_column :form_field_options, :weight
  end
end
