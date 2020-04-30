class DropExistingInventoryTables < ActiveRecord::Migration
  def self.up
    connection =  ActiveRecord::Base.connection
    inventory_tables = ['store_categories','store_types','stores','store_items','supplier_types','suppliers','indents','indent_items','purchase_orders','purchase_items','grns','grn_items']
    inventory_tables.each do |inventory_table|
      if connection.table_exists? inventory_table
        unless inventory_table.singularize.camelize.constantize.column_names.include? "is_deleted"
          drop_table inventory_table.to_sym
        end
      end
    end
  end

  def self.down
  end
end
