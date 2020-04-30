class BarcodeProperty < ActiveRecord::Base
  belongs_to :base_template

  ORIENTAIONS = [
    {:id=>1, :deg=>0, :name=>"horizontal" },
    {:id=>2, :deg=>270, :name=>"left vertical" },
    {:id=>3, :deg=>90, :name=>"right vertical" }
  ]


  def self.linked_to_keys(type)
    keys = []
    if type == 1
      #student
      keys = StudentAdditionalField.all(:conditions=>["input_type = 'text'"]).collect{|f| [f.name, f.name.split.map{|e| e.downcase}.join("_").to_sym]}
      keys = [["Admission No", "-1"]] + keys
      return keys
    elsif type ==  2
      #employee
      keys = AdditionalField.all(:conditions=>["input_type = 'text'"]).collect{|f| [f.name, f.name.split.map{|e| e.downcase}.join("_").to_sym]}
      keys = [["Employee No", "-1"]] + keys
      return keys
    else
      return []
    end
  end

end
