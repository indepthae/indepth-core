class AddingUniqueIndexOnUsersStudentsAndEmployees < ActiveRecord::Migration

  COLUMNS_LIST = {"User"=>{"entry"=>"username","index_name"=>"username_unique_index"},
    "Employee"=>{"entry"=>"employee_number","index_name"=>"employee_number_unique_index"},
    "ArchivedEmployee"=>{"entry"=>"employee_number","index_name"=>"employee_number_unique_index"},
    "Student"=>{"entry"=>"admission_no","index_name"=>"admission_no_unique_index"},
    "ArchivedStudent"=>{"entry"=>"admission_no","index_name"=>"admission_no_unique_index"}
  }
  MODEL_LIST = [User,Student,ArchivedStudent,Employee,ArchivedEmployee]
  def self.up
    MODEL_LIST.each do |model|
      if (MultiSchool rescue false)
        model.reset_column_information
        unless model.column_names.include?("school_id")
          add_column model.table_name.to_sym,:school_id,:integer
          add_index model.table_name.to_sym,:school_id
        end
        add_index model.table_name.to_sym,[COLUMNS_LIST["#{model}"]["entry"].to_sym,:school_id],:unique=>true, :name=>COLUMNS_LIST["#{model}"]["index_name"].to_sym
      else
        add_index model.table_name.to_sym,COLUMNS_LIST["#{model}"]["entry"].to_sym,:unique=>true, :name=>COLUMNS_LIST["#{model}"]["index_name"].to_sym
      end
    end
  end

  def self.down
    MODEL_LIST.each do |model|
      remove_index model.table_name.to_sym,:name=>COLUMNS_LIST["#{model}"]["index_name"].to_sym
    end
  end
end
