# IndepthOverrides
require 'dispatcher'
require 'overrides/indepth_student_controller'
#require 'overrides/indepth_user_controller'
require 'overrides/indepth_finance_controller'
require 'overrides/indepth_guardian_model'
require 'overrides/indepth_student_model'
require 'overrides/indepth_archived_student_model'
require 'overrides/indepth_finance_extensions_controller'
require 'overrides/indepth_archived_student_controller'
require 'overrides/indepth_custom_reports_controller'
require 'overrides/indepth_finance_settings_controller'
module IndepthOverrides
	def self.attach_overrides
    Dispatcher.to_prepare  do
      ::Student.class_eval { extend IndepthStudentExtend }
      ::Employee.class_eval { extend IndepthEmployeeExtend }
      ::StudentController.instance_eval { include IndepthStudentController }
      ::ArchivedStudentController.instance_eval { include IndepthArchivedStudentController }
      ::Student.instance_eval { include IndepthStudent }
      ::ArchivedStudent.instance_eval { include IndepthArchivedStudentModel }
      ::Guardian.instance_eval { include IndepthGuardian }
      ::ArchivedStudent.class_eval { extend IndepthArchivedStudentExtend }
      #	    	::UserController.instance_eval { include IndepthUserController }
      ::FinanceController.instance_eval {include IndepthFinanceController}
      ::FinanceExtensionsController.instance_eval {include IndepthFinanceExtensionsController}
      ::CustomReportsController.instance_eval {include IndepthCustomReportsController}
      ::Student.instance_eval {include IndepthStudentModel}
      ::Guardian.instance_eval {include IndepthGuardianModel}
      ::User.instance_eval{include IndepthOverrides::UserOverride}

      ::ApplicationController.instance_eval {include IndepthOverrides::ApplicationController}
      ::CalendarController.instance_eval {include IndepthOverrides::ApplicationController}
      ::EmployeeAttendanceController.instance_eval {include IndepthOverrides::ApplicationController}
      ::EventController.instance_eval {include IndepthOverrides::ApplicationController}
      ::FinanceController.instance_eval {include IndepthOverrides::ApplicationController}
      ::FinanceExtensionsController.instance_eval {include IndepthOverrides::ApplicationController}
      ::StudentController.instance_eval {include IndepthOverrides::ApplicationController}
      ::TimetableController.instance_eval {include IndepthOverrides::ApplicationController}
      ::UserController.instance_eval {include IndepthOverrides::UserController}
      ::FinanceTransaction.class_eval { extend IndepthFinanceTransaction }
      ::EmployeeController.instance_eval { include IndepthOverrides::EmployeeController}
      ::DataPalettesController.instance_eval {include IndepthOverrides::DataPalettesController}
      ::Employee.instance_eval {include IndepthOverrides::EmployeeClassMethods}
      ::DataExportsController.instance_eval { include IndepthOverrides::DataExportsController}
      ::ExportsController.instance_eval{ include IndepthOverrides::ExportsController}
      ::FinanceSettingsController.instance_eval{ include IndepthFinanceSettingsController}
    end
	end

	module IndepthStudent
    def self.included (base)
      base.instance_eval do
        validates_presence_of :familyid ,:if=> Proc.new{|as| as.revert_mode != 'Archival' }
        validates_numericality_of :familyid, :greater_than => 0 ,:less_than_or_equal_to => 99999999999,:if=> Proc.new{|as| as.revert_mode != 'Archival' }
        validate :check_for_family_id_and_admission_no_uniqueness
        # validate :check_for_family_id

        base.instance_eval do
          # alias_method_chain :archive_student, :tmpl
        end
      end
    end
    def check_for_family_id_and_admission_no_uniqueness      
      stud_adms_no = Student.all.collect(&:admission_no).map{|s| s.to_i}
      stud_family_ids = Student.all.collect(&:familyid).map{|s| s.to_i}
      if self.new_record?        
        if stud_adms_no.include?(self.familyid)        
          self.errors.add_to_base("Family id is already present as Admission no for other student")        
        end
        if stud_family_ids.include?(self.admission_no.to_i)
          self.errors.add_to_base("Admission number is already present as Family id for other student")
        end      
        if self.admission_no.to_i == self.familyid.to_i        
          self.errors.add_to_base("Admission number and Family id should not be same")
        end
      else        
        if ((self.changed.include? 'admission_no') or (self.changed.include? 'familyid')) and self.admission_no.to_i == self.familyid.to_i
          self.errors.add_to_base("Admission number and Family id should not be same")
        elsif self.changed.include? 'familyid' and stud_adms_no.include?(self.familyid)                
          self.errors.add_to_base("Family id is already present as Admission no for other student")        
        elsif self.changed.include? 'admission_no' and stud_family_ids.include?(self.admission_no.to_i)        
          self.errors.add_to_base("Admission number is already present as Family id for other student")
        end 
      end
    end

    #    def archive_student_with_tmpl(status, leaving_date)
		#     student_attributes = self.attributes
		#     student_attributes["former_id"]= self.id
		#     student_attributes["status_description"] = status
		#     student_attributes["former_has_paid_fees"] = self.has_paid_fees
		#     student_attributes["former_has_paid_fees_for_batch"] = self.has_paid_fees_for_batch
		#     student_attributes.merge!(:sibling_id => sibling_id)
		#     student_attributes.delete "id"
		#     student_attributes.delete "has_paid_fees"
		#     student_attributes.delete "has_paid_fees_for_batch"
		#     student_attributes.delete "created_at"
		#     archived_student = ArchivedStudent.new(student_attributes)
		#     archived_student.photo = self.photo if self.photo.file?
		#     archived_student.date_of_leaving = leaving_date
		#     puts "))))))))))))))))))))))))))))))))))))))))))"
		#     puts archived_student.inspect
		#     if archived_student.save
		#       guardians = self.guardians
		#       self.user.soft_delete
		#       if archived_student.siblings.present?
		#         archived_guardians=archived_student.archived_guardians
		#         archived_guardians.each do |ag|
		#           ag.destroy
		#         end
		#       end
		#       guardians.each do |g|
		#         g.archive_guardian(archived_student.id, self.id)
		#       end
		#       self.destroy
		#     end
		# end
	end

	module IndepthGuardian
    def self.included (base)
      base.instance_eval do
        alias_method_chain :create_guardian_user , :tmpl
        #validate :check_family_id_and_admission_no
      end
    end

    def create_guardian_user_with_tmpl(student)
      #	    	puts "*************************inside my method **********************"
      user = User.new do |u|
		    u.first_name = self.first_name
		    u.last_name = self.last_name
		    u_name="p"+student.admission_no.to_s
		    begin
          user_record=User.find_by_username(u_name)
          if user_record.present?
            u_name=u_name.next
          end
		    end while user_record.present?
		    u.username = u_name
		    familyid = self.familyid
		    u.password = "#{familyid}123"
		    u.role = 'Parent'
		    u.email = ( email != '' or User.active.find_by_email(self.email) ) ? self.email.to_s : ""
      end
      if user.save
        unless self.update_attributes(:user_id => user.id)
          raise ActiveRecord::Rollback
        end
      end
		end
    
    def check_family_id_and_admission_no
      stud_adms_no = Student.all.collect(&:admission_no).map{|s| s.to_i}
      stud_family_ids = Student.all.collect(&:familyid).map{|s| s.to_i}
      student = Student.find_by_id(self.ward_id)      
      if stud_adms_no.include?(self.familyid)        
        self.errors.add_to_base("Family id is already present as Admission no for other student.")        
      end
      if stud_family_ids.include?(student.admission_no.to_i)
        self.errors.add_to_base("Admission number is already present as Family id for other student.")
      end      
      if student.admission_no.to_i == self.familyid.to_i        
        self.errors.add_to_base("Admission number and Family id should not be same.")
      end
    end
	end

	module IndepthStudentExtend
    def self.extended(base)
      base.class_eval do
        cattr_accessor :fields_to_search_ext, :fields_to_display_ext
        named_scope :family_name_admssn_no, lambda { |query| {:conditions => ["ltrim(rtrim(familyid)) LIKE ? OR ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ? OR admission_no LIKE ? OR concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? OR concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ?", "%#{query}", "#{query}%", "#{query}%", "#{query}%", "#{query}%", "#{query}%", "#{query}%"]} }
        named_scope :familyid_equals, lambda { |val| {:conditions => ["students.familyid LIKE BINARY?", "%#{val}"]} }
        base.fields_to_search_ext=YAML.load_file(File.join(Rails.root, "vendor/plugins/indepth_overrides/config", "report_fields_extension.yml"))[:fields_to_search_ext][:student]
        base.fields_to_display_ext=YAML.load_file(File.join(Rails.root, "vendor/plugins/indepth_overrides/config", "report_fields_extension.yml"))[:fields_to_display_ext][:student]
      end
		end
	end
	module IndepthEmployeeExtend
    def self.extended(base)
      base.class_eval do
        cattr_accessor :fields_to_search_ext, :fields_to_display_ext
        base.fields_to_search_ext=YAML.load_file(File.join(Rails.root, "vendor/plugins/indepth_overrides/config", "report_fields_extension.yml"))[:fields_to_search_ext][:employee]
        base.fields_to_display_ext=YAML.load_file(File.join(Rails.root, "vendor/plugins/indepth_overrides/config", "report_fields_extension.yml"))[:fields_to_display_ext][:employee]
      end
		end
	end

	module IndepthArchivedStudentExtend
    def self.extended(base)
      base.class_eval do
        named_scope :family_name_admssn_no, lambda { |query| {:conditions => ["ltrim(rtrim(familyid)) LIKE ? OR ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ? OR admission_no LIKE ? OR concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? OR concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ?", "%#{query}", "#{query}%", "#{query}%", "#{query}%", "#{query}%", "#{query}%", "#{query}%"]} }
      end
		end
	end

	module IndepthFinanceTransaction
    def self.included (base)
      base.instance_eval do
      end
    end

    def self.extended(base)
      base.class_eval do
        def get_poly_finance_type_name
          finance_type = self.finance_type
          finance_fee_name = case finance_type
          when "TransportFee" then
            self.finance.transport_fee_collection.name
          when "HostelFee" then
            self.finance.hostel_fee_collection.name
          when "FinanceFee" then
            self.finance.finance_fee_collection.name
          when "InstantFee" then
            if self.finance.instant_fee_category_id.nil?
              self.finance.custom_category
            elsif self.finance.custom_category.nil?
              self.finance.instant_fee_category.name
            end
          else
            self.title
          end
          return finance_fee_name
				end

				def can_show_column
					cheque_date = self.respond_to?(:cheque_date) ? (self.cheque_date.present? ? self.cheque_date.to_s : "") : ""
					bank_name = self.respond_to?(:bank_name) ? (self.bank_name.present? ? self.bank_name.to_s : "") : ""
					payment_note = self.respond_to?(:payment_note) ? (self.payment_note.present? ? self.payment_note.to_s : "") : ""

					a = cheque_date + bank_name + payment_note
					return a.present? ? true : false

				end
      end
		end

	end

end
