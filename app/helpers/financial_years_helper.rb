module FinancialYearsHelper
  def fetch_obj_path(obj, alias_name = nil)
    path_name = fetch_path_name obj, alias_name
    eval "#{obj.new_record? ? path_name.pluralize : path_name}_path"
    # eval "#{obj.new_record? ? (alias_name.try(:pluralize) || obj.class.name.tableize) :
    #          (alias_name || obj.class.name.underscore)}_path"
  end

  def fetch_obj_title(obj, alias_name = nil)
    "#{obj.new_record? ? 'create' : 'update'}_#{ alias_name || obj.class.name.underscore}"
  end

  def fetch_path_name obj, alias_name = nil
    return alias_name.present? ? 'create_' + alias_name : obj.class.name.underscore if obj.new_record?
    alias_name.present? ? 'update_' + alias_name.singularize : obj.class.name.underscore
  end
end
