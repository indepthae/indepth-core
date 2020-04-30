require 'dispatcher'
# FedenaTransport
require 'finance_transaction_transport_extension'
require 'employee_transport_extension'
require 'student_transport_extension'
module FedenaTransport
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_transport do
      ::Batch.instance_eval { include BatchExtension }
      ::Batch.class_eval {
        def active_transports
          academic_year_id = AcademicYear.active.first.try(:id)
          transports.in_academic_year(academic_year_id) 
        end
      }
      ::Employee.instance_eval { include  EmployeeExtension }      
      ::EmployeeDepartment.instance_eval { include EmployeeDepartmentExtension }
      ::FinanceTransaction.instance_eval { include FinanceTransactionTransportExtension }      
      ::Fine.instance_eval { include FineExtension }
      ::MasterFeeDiscount.instance_eval { include MasterFeeDiscountExtension }
      ::MasterFeeParticular.instance_eval { include MasterFeeParticularExtension }
      ::MultiFeeDiscount.instance_eval { attr_accessor :transport_fee_ids
        has_many :transport_fee_discounts, :dependent => :destroy }
      ::Student.instance_eval { include  StudentExtension }
      ::TaxSlab.instance_eval { include TaxSlabExtension }
      ::TaxPayment.instance_eval { include TaxPaymentExtension }
      ::AcademicYear.instance_eval { include AcademicYearExtension }
      ::Configuration.instance_eval { extend ConfigurationExtension }
      ::ArchivedStudent.instance_eval { include  ArchivedStudentExtension }   
      ::ArchivedEmployee.instance_eval { include  ArchivedEmployeeExtension }   
      ::StudentController.instance_eval { include PassengerControllerExtension }
      ::EmployeeController.instance_eval { include PassengerControllerExtension }
      ::FinancialYear.instance_eval { has_many :transport_fee_collections }
    end
  end


  def self.dependency_delete(student)
    student.transport.destroy if student.transport.present?
    student.transport_fees.destroy_all
  end

  def self.dependency_check(record,type)
    if type == "permanant"
      if record.class.to_s == "Student" or record.class.to_s == "Employee"
        return true if record.transport.present?
        return true if record.transport_fees.active.present?
      end
    end
    return true if record.class.to_s == "Employee" and record.routes.present?
    return false
  end

  def self.student_profile_fees_hook
    "transport_fee/student_profile_fees"
  end

  def self.student_profile_fees_by_batch_hook
    "transport_fee/student_profile_fees"
  end

  def self.mobile_student_profile_fees_hook
    "transport_fee/mobile_student_profile_fees"
  end
  
  def self.transport_admission_hook
    "transport/transport_assign"
  end
  
  def self.employee_dependency_hook
    "transport_employees/employee_route_assignment"
  end
  
  module PassengerControllerExtension
    def self.included(base)
      base.instance_eval do
        helper :transport
      end
    end
    
    def transport_admission_data(passenger)
      @enable_transport = (passenger.enable_transport.to_i == 1)
      @transport = passenger.transport
      @receiver_type = passenger.class.to_s.downcase
      if @transport.present?
        academic_year_id = AcademicYear.active.first.id
        @routes = Route.in_academic_year(academic_year_id)
        @mode = @transport.mode
        @different_route = Configuration .get_config_value('DifferentRoutes')
        @pickup_stops = @transport.pickup_route.vehicle_stops if @transport.pickup_route.present?
        @drop_stops = @transport.drop_route.vehicle_stops if @transport.drop_route.present?
        @currency ||= Configuration.currency
      end
    end    
  end

  module EmployeeDepartmentExtension
    def self.included(base)
      base.instance_eval do 
        has_many :transport_fees, :as=>:groupable
        has_many :transport_fee_collection_assignments, :as => :assignee
        has_many :transport_fee_collections, :through => :transport_fee_collection_assignments, :class_name => 'TransportFeeCollection'
      end
    end
    
    def working_days_for_range(start_date,end_date)
      holidays = fetch_holiday_event_dates
      date_ranges = start_date .. end_date 
      (date_ranges.to_a - holidays)
    end
    
    def fetch_holiday_event_dates
      @common_holidays ||= Event.holidays.is_common
      @dept_holidays = events.select{|e| e.is_holiday }
      all_holiday_events = @dept_holidays+@common_holidays
      event_holidays = []
      all_holiday_events.each do |event|
        event_holidays+=event.dates
      end
      return event_holidays #array of holiday event dates
    end
  end
  
  module BatchExtension
    def self.included(base)
      base.instance_eval do 
        has_many :transport_fees, :as=>:groupable
        has_many :transports, :through=>:students
        has_many :transport_fee_collection_assignments, :as => :assignee
        has_many :transport_fee_collections, :through => :transport_fee_collection_assignments, :class_name => 'TransportFeeCollection'
      end
    end
    
    def working_days_for_range(start_date,end_date)
      holidays = fetch_holiday_event_dates
      range=[]
      total_weekday_sets=self.attendance_weekday_sets.select{|a| a.start_date <= end_date and end_date >= start_date}
      total_weekday_sets.each do |weekdayset|
        week_day_start=[]
        week_day_end=[]
        week_day_start << weekdayset.start_date.to_date
        week_day_start << start_date.to_date
        week_day_end << weekdayset.end_date.to_date
        week_day_end << end_date.to_date
        weekdayset_date_range=week_day_start.max..week_day_end.min
        weekday_ids=weekdayset.weekday_set.weekday_ids
        non_holidays=weekdayset_date_range.to_a-holidays
        range << non_holidays.select{|d| weekday_ids.include? d.wday}
      end
      range=range.flatten
      return range
    end
    
    def fetch_holiday_event_dates
      @common_holidays ||= Event.holidays.is_common
      @batch_holidays = events.select{|e| e.is_holiday }
      all_holiday_events = @batch_holidays+@common_holidays
      event_holidays = []
      all_holiday_events.each do |event|
        event_holidays+=event.dates
      end
      return event_holidays #array of holiday event dates
    end
    
  end
  
  module TaxSlabExtension
    def self.included(base)
      base.instance_eval do         
        has_many :transport_fee_collections, :through => :collectible_tax_slabs, :source => :collection,
          :source_type => 'TransportFeeCollection'
      end
    end
  end
    
  module TaxPaymentExtension
    def self.included(base)
      base.class_eval do
        def self.transport_fee_tax_payments(start_date, end_date)
          TaxPayment.all(:conditions => ["transaction_date 
            BETWEEN '#{start_date}' AND '#{end_date}' AND finance_type = 'TransportFee' AND
            (ftrr.fee_account_id IS NULL OR fa.is_deleted = false)"],
                         :select => "DISTINCT tax_payments.id as tax_payment_id,
                               tax_payments.tax_amount AS tax_amount, ts.name AS slab_name, 
                               ts.rate AS slab_rate, ts.id AS slab_id, tfc.id AS collection_id, 
                               tfc.name AS collection_name, fts.transaction_date as transaction_date",
                         :joins => "INNER JOIN finance_transactions fts ON fts.id = tax_payments.finance_transaction_id
                       INNER JOIN finance_transaction_receipt_records ftrr
                                  FORCE INDEX (index_by_transaction_and_receipt)
                               ON ftrr.finance_transaction_id = fts.id
                        LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id
                       INNER JOIN transport_fees tf
                               ON tf.id = tax_payments.taxed_fee_id AND tax_payments.taxed_fee_type = 'TransportFee'
                       INNER JOIN transport_fee_collections tfc
                               ON tfc.id = tf.transport_fee_collection_id
                       INNER JOIN collectible_tax_slabs cts
                               ON cts.collection_id = tfc.id AND cts.collection_type = 'TransportFeeCollection'
                       INNER JOIN tax_slabs ts ON ts.id = cts.tax_slab_id")
        end
      end
    end
  end
    
  module FineExtension
    def self.included(base)
      base.instance_eval do
        has_many :transport_fee_collections
      end
    end
  end

  module MasterFeeDiscountExtension
    def self.included(base)
      base.instance_eval do
        has_many :transport_fee_discounts
      end
    end
  end

  module MasterFeeParticularExtension
    def self.included(base)
      base.instance_eval do
        has_many :transport_fee_collections
      end
    end
  end

  module AcademicYearExtension
    def self.included(base)
      base.instance_eval do
        has_many :vehicle_stops
        named_scope :all_except_one, lambda{|aca_id| {:conditions => ['academic_years.id <> ?', aca_id]}}
        
        after_update :update_transort_data
      end
      
      def update_transort_data
        if self.is_active_changed? and self.is_active
          school_id = MultiSchool.current_school.id
          stops = VehicleStop.first(:conditions => {:academic_year_id => nil})
          if stops.present?
            VehicleStop.update_all({:academic_year_id => self.id}, {:school_id => school_id, :academic_year_id => nil})
            Vehicle.update_all({:academic_year_id => self.id}, {:school_id => school_id, :academic_year_id => nil})
            Route.update_all({:academic_year_id => self.id}, {:school_id => school_id, :academic_year_id => nil})
            Transport.update_all({:academic_year_id => self.id}, {:school_id => school_id, :academic_year_id => nil})
          end
        end
      end
    end
  end
  
  module ArchivedStudentExtension
    def self.included(base)
      base.instance_eval do
        has_many :archived_transports, :as => 'receiver', :dependent => :destroy
        before_destroy :revert_transort_data
      end
    
      def revert_transort_data
        self.archived_transports.each{|t| t.revert_archived_transport(former_id, 'Student')}
      end
    end
  end
  
  module ArchivedEmployeeExtension
    def self.included(base)
      base.instance_eval do
        has_many :archived_transports, :as => 'receiver', :dependent => :destroy
        before_destroy :revert_transort_data
      end
    
      def revert_transort_data
        self.archived_transports.each{|t| t.revert_archived_transport(former_id, 'Employee')}
      end
    end
  end
  
  module ConfigurationExtension
    def common_route
      different_route = get_config_value('DifferentRoutes')
      (different_route.nil? ? false : (different_route.to_i == 0))
    end
  end
end

