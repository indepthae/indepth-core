module FedenaInventory
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_inventory do
      ::FinancialYear.instance_eval {
        has_many :grns
        has_many :invoices
      }
    end
  end

  def self.dependency_check(record,type)
    if type == "permanant"
      if record.class.to_s == "Employee"
        return true if Indent.count(:joins=>"LEFT OUTER JOIN `users` ON `users`.id = `indents`.user_id LEFT OUTER JOIN `users` managers_indents ON `managers_indents`.id = `indents`.manager_id",:conditions=>["(indents.user_id=? or indents.manager_id=?) and indents.is_deleted ='0'",record.user_id,record.user_id]) > 0
      end
    end
    return false
  end

  def self.csv_export_list
    return ["store", "store_items", "supplier"]
  end

  def self.csv_export_data(report_type,params)
    case report_type
    when "store"
      data = Store.store_data(params)
    when "store_items"
      data = StoreItem.store_items_data(params)
    when "supplier"
      data = Supplier.supplier_data(params)
    end
  end

  def self.tax_mode
    key = Configuration.find_or_create_by_config_key("inventory_tax_mode").config_value
    if key.nil? || key.to_i == 1
      return :new
    elsif key.to_i == 0
      return :old
    else
      return :invalid
    end
  end

  def self.new_tax_mode?
    tax_mode == :new
  end

  def self.old_tax_mode?
    tax_mode == :old
  end

  def self.tax_mode= mode
    return false unless [:new,:old].include? mode
    config = Configuration.find_or_create_by_config_key("inventory_tax_mode")
    config_value = (mode == :old) ? 0 : 1
    Configuration.set_value("inventory_tax_mode", config_value)
  end

  def self.tax_mode_key
    (Configuration.find_or_create_by_config_key("inventory_tax_mode").config_value || 1).to_i
  end
end
