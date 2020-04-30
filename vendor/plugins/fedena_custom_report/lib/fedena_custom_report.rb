#FedenaCustomReports
require "report_extensions"
require 'dispatcher'

module FedenaCustomReport
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_custom_report do
      attach_report_data_methods
      attach_object_stringify
      Student.extend StudentExtensions
      Employee.extend EmployeeExtensions
    end
  end
  
  def self.attach_report_data_methods
    # if there is special scope for associated field make an alias to the scope method :report_data
    Batch.instance_eval do
      alias :report_data :active
    end
    StudentCategory.instance_eval do
      alias :report_data :active
    end
    Course.instance_eval do
      alias :report_data :active
    end
  end

  def self.attach_object_stringify
    # stringify model objects, add definition to the 'to_s' method of models/classes
    Batch.class_eval{def to_s;"#{full_name}";end}
    Course.class_eval{def to_s;"#{course_name}";end}
    StudentCategory.class_eval{def to_s;"#{name}";end}
    EmployeeDepartment.class_eval{def to_s;"#{name}";end}
    EmployeeCategory.class_eval{def to_s;"#{name}";end}
    EmployeeGrade.class_eval{def to_s;"#{name}";end}
    EmployeePosition.class_eval{def to_s;"#{name}";end}
    Country.class_eval{def to_s;"#{name}";end}
    Guardian.class_eval{def to_s;"#{first_name}";end}
  end
end