class AddPrintTokenToApplicants < ActiveRecord::Migration
  def self.up
    add_column :applicants, :print_token, :string
  end

  def self.down
    remove_column :applicants, :print_token
  end
end
