class CreateTableJobResourceLocators < ActiveRecord::Migration
  def self.up
    create_table :job_resource_locators do |t|
      t.integer :job_id
      t.string  :context
      t.string  :locator
      t.integer :status
      t.string  :last_message
      
      t.timestamps
    end
  end

  def self.down
    drop_table :job_resource_locators
  end
end
