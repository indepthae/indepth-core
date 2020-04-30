class CreateRemarkTemplate < ActiveRecord::Migration
  def self.up
    create_table :remark_templates do |t|
      t.references :remark_bank
      t.string :name
      t.string :template_body
      t.references :school
    end
  end

  def self.down
    drop_table :remark_templates
  end
end
