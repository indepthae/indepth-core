class AddIdUpdatedAtCreatedAtTally < ActiveRecord::Migration
  def self.up
    columns_to_create = {"id" => "INT PRIMARY KEY NOT NULL AUTO_INCREMENT","created_at" => "datetime","updated_at" => "datetime"}
    model_list = [TallyExportConfiguration]
    model_list.each do |model|
      model.reset_column_information
      create_columns = columns_to_create.keys - model.column_names
      create_columns.each do |column|
        add_column model.table_name.to_sym,column.to_sym,columns_to_create[column].to_sym
      end
    end
  end

  def self.down
  end
end
