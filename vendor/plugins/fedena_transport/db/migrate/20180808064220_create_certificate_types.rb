class CreateCertificateTypes < ActiveRecord::Migration
  def self.up
    create_table :certificate_types do |t|
      t.string :name
      t.boolean :send_reminders, :default => true
      t.boolean :is_active, :default => true
      t.references :school

      t.timestamps
    end
  end

  def self.down
    drop_table :certificate_types
  end
end
