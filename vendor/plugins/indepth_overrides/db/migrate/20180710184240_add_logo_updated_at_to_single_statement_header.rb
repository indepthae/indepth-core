class AddLogoUpdatedAtToSingleStatementHeader < ActiveRecord::Migration
  def self.up
    add_column :single_statement_headers, :logo_updated_at,  :datetime
  end

  def self.down
    remove_column :single_statement_headers, :logo_updated_at
  end
end
