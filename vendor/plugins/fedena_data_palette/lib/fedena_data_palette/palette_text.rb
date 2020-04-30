# To change this template, choose Tools | Templates
# and open the template in the editor.

module FedenaDataPalette

  module NewsPaletteText
    def self.included(base)
      base.class_eval do
        def news_palette_text
          "<a href='/news/view/#{self.id}'><div class='linked-palette'>
           <div class='subcontent-header themed_text'>#{self.title}</div>
           <div class='subcontent-footer'>
            <div class='footer-date'>#{t('posted_on')} #{format_date(FedenaTimeSet.current_time_to_local_time(self.created_at).to_date,:format=>:short_date)}</div>
            <div class='footer-comment'>
             <span class='footer-comment-icon'></span> #{self.comments.count}
            </div>
           </div></div></a>".html_safe
        end
      end
    end
  end

  module EventsPaletteText
    def self.included(base)
      base.class_eval do
        def events_palette_text
          "<div class='subcontent-header'>#{self.title}</div>
           <div class='subcontent-info'>
            #{format_date(self.start_date,:format=>:long)} - #{format_date(self.end_date,:format=>:long)}
           </div>
           <div class='subcontent-info'>#{self.description}</div> ".html_safe
        end
        def fees_due_palette_text
          collection = self.origin
          unless collection.nil?
            col_class = collection.class.name
            fee_type = (col_class == "FinanceFeeCollection") ? "default_col" : (col_class == "HostelFeeCollection") ? "hostel_col" : (col_class == "TransportFeeCollection") ? "transport_col" : "none_col"
            cur_usr = Authorization.current_user
            if col_class == "FinanceFeeCollection"
              if cur_usr.admin or (cur_usr.role_symbols & [:finance_control,:fee_submission,:finance_reports,:revert_transaction]).present?
                "<div class='subcontent-header'>#{collection.name}</div>
           <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>
           <div class='subcontent-info'>#{t("batches_text")} : #{collection.batches.collect(&:full_name).join(", ")}</div> ".html_safe
              elsif cur_usr.student
                stu = cur_usr.student_record
                fee_record = FinanceFee.find_by_fee_collection_id_and_student_id(collection.id,stu.id)
                if fee_record.nil?
                  "<div class='subcontent-header'>#{collection.name}</div>
           <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>
           <div class='subcontent-info'>#{t("batch")} : #{stu.batch.full_name}</div> ".html_safe
                else
                  "<a href='/student/fee_details/#{stu.id}/#{collection.id}'><div class='linked-palette'>
           <div class='subcontent-header themed_text'>#{collection.name}</div>
           <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>
           <div class='subcontent-info'>#{t("batch")} : #{stu.batch.full_name}</div></div></a> ".html_safe
                end
              elsif cur_usr.parent
                stu = cur_usr.guardian_entry.current_ward
                fee_record = FinanceFee.find_by_fee_collection_id_and_student_id(collection.id,stu.id)
                if fee_record.nil?
                  "<div class='subcontent-header'>#{collection.name}</div>
           <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>
           <div class='subcontent-info'>#{t("batch")} : #{stu.batch.full_name}</div>".html_safe
                else
                  "<a href='/student/fee_details/#{stu.id}/#{collection.id}'><div class='linked-palette'>
           <div class='subcontent-header themed_text'>#{collection.name}</div>
           <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>
           <div class='subcontent-info'>#{t("batch")} : #{stu.batch.full_name}</div></div></a> ".html_safe
                end
              end
            else
              if col_class == "HostelFeeCollection"
                if cur_usr.student
                  fee_record = HostelFee.find_by_hostel_fee_collection_id_and_student_id(collection.id, cur_usr.student_record.id)
                  target_url = "/hostel_fee/student_profile_fee_details/#{cur_usr.student_record.id}/#{collection.id}"
                  
                  if cur_usr.student or cur_usr.parent
                    if collection.batch
                      if fee_record.present?
                        "<a href=#{target_url}><div class='linked-palette'>
                       <div class='subcontent-header themed_text'>#{collection.name}</div>
                       <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>
                       <div class='subcontent-info'>#{t("batch")} : #{collection.batch.full_name}</div></div></a> #".html_safe
                      else
                        "<div class='subcontent-header'>#{collection.name}</div>
                       <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>
                       <div class='subcontent-info'>#{t("batch")} : #{collection.batch.full_name}</div> #".html_safe
                      end
                    else
                      "<a href=#{target_url}><div class='linked-palette'>
                     <div class='subcontent-header themed_text'>#{collection.name}</div>
                     <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div></div></a>#".html_safe
                    end
                  else
                    if collection.batch
                      "<div class='subcontent-header'>#{collection.name}</div>
                     <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>
                     <div class='subcontent-info'>#{t("batch")} : #{collection.batch.full_name}</div> ##".html_safe
                    else
                      "<div class='subcontent-header'>#{collection.name}</div>
                     <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>##".html_safe
                    end
                  end
                  
                elsif cur_usr.parent
                  fee_record = HostelFee.find_by_hostel_fee_collection_id_and_student_id(collection.id, cur_usr.guardian_entry.current_ward_id)
                  target_url = "/hostel_fee/student_profile_fee_details/#{cur_usr.guardian_entry.current_ward_id}/#{collection.id}"
                end
              elsif col_class == "TransportFeeCollection"
                if cur_usr.student
                  fee_record = TransportFee.find_by_transport_fee_collection_id_and_receiver_id(collection.id, cur_usr.student_record.id)
                  target_url = "/transport_fee/student_profile_fee_details/#{cur_usr.student_record.id}/#{collection.id}"
                  stu = cur_usr.student_record
                  
                  if fee_record.present?
                    "<a href=#{target_url}><div class='linked-palette'>
                       <div class='subcontent-header themed_text'>#{collection.name}</div>
                       <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>
                       <div class='subcontent-info'>#{t("batches_text")} : #{stu.batch.full_name}</div></div></a> ".html_safe
                  else
                    "<div class='subcontent-header'>#{collection.name}</div>
                       <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>
                       <div class='subcontent-info'>#{t("batches_text")} : #{stu.batch.full_name}</div> ".html_safe
                  end
                  
                elsif cur_usr.parent
                  fee_record = TransportFee.find_by_transport_fee_collection_id_and_receiver_id(collection.id, cur_usr.guardian_entry.current_ward_id)
                  target_url = "/transport_fee/student_profile_fee_details/#{cur_usr.guardian_entry.current_ward_id}/#{collection.id}"
                  stu = cur_usr.guardian_entry.current_ward
                  
                  if fee_record.present?
                    "<a href=#{target_url}><div class='linked-palette'>
                       <div class='subcontent-header themed_text'>#{collection.name}</div>
                       <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>
                       <div class='subcontent-info'>#{t("batches_text")} : #{stu.batch.full_name}</div></div></a> ".html_safe
                  else
                    "<div class='subcontent-header'>#{collection.name}</div>
                       <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>
                       <div class='subcontent-info'>#{t("batches_text")} : #{stu.batch.full_name}</div> ".html_safe
                  end
                  
                else
                  if collection.batches.present?
                    "<div class='subcontent-header'>#{collection.name}</div>
                     <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>
                     <div class='subcontent-info'>#{t("batches_text")} : #{collection.batches.collect(&:full_name).join(", ")}</div> ".html_safe
                  else
                    "<div class='subcontent-header'>#{collection.name}</div>
                     <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>".html_safe
                  end
                end
              end
              ##              if cur_usr.student or cur_usr.parent
              ##                if collection.batch
              ##                  if fee_record.present?
              ##                    "<a href=#{target_url}><div class='linked-palette'>
              #           <div class='subcontent-header themed_text'>#{collection.name}</div>
              #           <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>
              #           <div class='subcontent-info'>#{t("batch")} : #{collection.batch.full_name}</div></div></a> #".html_safe
              ##                  else
              ##                    "<div class='subcontent-header'>#{collection.name}</div>
              #           <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>
              #           <div class='subcontent-info'>#{t("batch")} : #{collection.batch.full_name}</div> #".html_safe
              ##                  end
              ##                else
              ##                  "<a href=#{target_url}><div class='linked-palette'>
              #           <div class='subcontent-header themed_text'>#{collection.name}</div>
              #           <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div></div></a>#".html_safe
              #                end
              #              else
              #                if collection.batch
              #                  "<div class='subcontent-header'>#{collection.name}</div>
              #           <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>
              #           <div class='subcontent-info'>#{t("batch")} : #{collection.batch.full_name}</div> ##".html_safe
              #                else
              #                  "<div class='subcontent-header'>#{collection.name}</div>
              #           <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>##".html_safe
              #                end
              #              end
            end
          else
            col_class = self.origin_type
            fee_type = (col_class == "FinanceFeeCollection") ? "default_col" : (col_class == "HostelFeeCollection") ? "hostel_col" : (col_class == "TransportFeeCollection") ? "transport_col" : "none_col"
            "<div class='subcontent-header'>#{t("deleted_collection")}</div>
           <div class='subcontent-info'>#{t("fee_type")} : #{t(fee_type)}</div>".html_safe
          end
        end

      end
    end
  end

  module StudentsPaletteText
    def self.included(base)
      base.class_eval do
        def admitted_students_palette_text
          u=Authorization.current_user
          if(u.role_symbols & [:admin, :admission, :students_control, :student_view]).empty?
            "<div class='subcontent-header'>#{self.full_name}</div>
          <div class='subcontent-info'>#{t("adm_no")} : #{self.admission_no}</div>
          <div class='subcontent-info'>#{t("batch")} : #{self.batch.full_name}</div>".html_safe
          else
            "<a href='/student/profile/#{self.id}'><div class='linked-palette'>
          <div class='subcontent-header themed_text'>#{self.full_name}</div>
          <div class='subcontent-info'>#{t("adm_no")} : #{self.admission_no}</div>
          <div class='subcontent-info'>#{t("batch")} : #{self.batch.full_name}</div></div></a>".html_safe
          end
        end
      end
    end
  end

  module ArchivedStudentsPaletteText
    def self.included(base)
      base.class_eval do
        def relieved_students_palette_text
          u=Authorization.current_user
          if(u.role_symbols & [:admin, :students_control, :student_view]).empty?
            "<div class='subcontent-header'>#{self.full_name}</div>
          <div class='subcontent-info'>#{t("adm_no")} : #{self.admission_no}</div>
          <div class='subcontent-info'>#{t("batch")} : #{self.batch.full_name}</div>".html_safe
          else
            "<a href='/archived_student/profile/#{self.id}'><div class='linked-palette'>
          <div class='subcontent-header themed_text'>#{self.full_name}</div>
          <div class='subcontent-info'>#{t("adm_no")} : #{self.admission_no}</div>
          <div class='subcontent-info'>#{t("batch")} : #{self.batch.full_name}</div></div></a>".html_safe
          end
        end
      end
    end
  end

  module AttendancePaletteText
    def self.included(base)
      base.class_eval do
        def absent_students_palette_text
          attendace_lock =  AttendanceSetting.is_attendance_lock
          if attendace_lock
            academic_days = MarkedAttendanceRecord.dailywise_working_days(self.batch_id)
            unless academic_days.include?(self.month_date)
              return
            end
          end
          return if self.attendance_label.try(:attendance_type) == "Late"
          leave_type = (self.forenoon == true and self.afternoon == true) ? "Full Day" : (self.forenoon == true ? "Forenoon" : "Afternoon")
          u=Authorization.current_user
          stu = self.student
          unless stu
            stu = ArchivedStudent.find_by_former_id(self.student_id)
            target_url = "/archived_student/profile/#{stu.id}"
          else
            target_url = "/student/profile/#{stu.id}"
          end
          if (u.role_symbols & [:admin,:manage_course_batch,:admission,:students_control,:student_view,:manage_users]).present?
            "<a href=#{target_url}><div class='linked-palette'>
          <div class='subcontent-header themed_text'>#{stu.full_name}</div>
          <div class='subcontent-info'>#{t("adm_no")} : #{stu.admission_no}</div>
          <div class='subcontent-info'>#{t("batch")} : #{self.batch.full_name}</div>
          <div class='subcontent-info'>Absent for : #{leave_type}</div></div></a>".html_safe
          else
            "<div class='subcontent-header'>#{stu.full_name}</div>
          <div class='subcontent-info'>#{t("adm_no")} : #{stu.admission_no}</div>
          <div class='subcontent-info'>#{t("batch")} : #{self.batch.full_name}</div>
          <div class='subcontent-info'>Absent for : #{leave_type}</div>".html_safe
          end
        end
      end
    end
  end

  module EmployeesPaletteText
    def self.included(base)
      base.class_eval do
        def admitted_employees_palette_text
          u=Authorization.current_user
          if(u.role_symbols & [:admin, :hr_basics, :employee_search]).empty?
            "<div class='subcontent-header'>#{self.full_name}</div>
          <div class='subcontent-info'>#{t("emp_no")} : #{self.employee_number}</div>
          <div class='subcontent-info'>#{t("department")} : #{self.employee_department.name}</div>".html_safe
          else
            "<a href='/employee/profile/#{self.id}'><div class='linked-palette'>
          <div class='subcontent-header themed_text'>#{self.full_name}</div>
          <div class='subcontent-info'>#{t("emp_no")} : #{self.employee_number}</div>
          <div class='subcontent-info'>#{t("department")} : #{self.employee_department.name}</div></div></a>".html_safe
          end
        end
      end
    end
  end

  module ArchivedEmployeesPaletteText
    def self.included(base)
      base.class_eval do
        def removed_employees_palette_text
          u=Authorization.current_user
          if(u.role_symbols & [:admin, :hr_basics, :employee_search]).empty?
            "<div class='subcontent-header'>#{self.full_name}</div>
          <div class='subcontent-info'>#{t("emp_no")} : #{self.employee_number}</div>
          <div class='subcontent-info'>#{t("department")} : #{self.employee_department.name}</div>".html_safe
          else
            "<a href='/archived_employee/profile/#{self.id}'><div class='linked-palette'>
          <div class='subcontent-header themed_text'>#{self.full_name}</div>
          <div class='subcontent-info'>#{t("emp_no")} : #{self.employee_number}</div>
          <div class='subcontent-info'>#{t("department")} : #{self.employee_department.name}</div></div></a>".html_safe
          end
        end
      end
    end
  end

  module EmployeeAttendancePaletteText
    def self.included(base)
      base.class_eval do
        def employees_on_leave_palette_text
          employee = self.employee
          leave_type = self.is_half_day ? "half_day" : "full_day"
          if employee.user.admin
            leave_app_source = "leave_applications"
            attendance_source = "report"
          elsif employee.user.manager
            leave_app_source = "pending_leave_applications"
            attendance_source = "reportees_leaves"
          else
            leave_app_source = "my_leave_applications"
            attendance_source = "profile"
          end
          if self.apply_leave.present?
            target_url = "/employee_attendance/leave_application/#{self.apply_leave_id}?from=#{leave_app_source}"
          else
            target_url = "/employee_attendance/view_attendance/#{self.id}?from=#{attendance_source}"
          end
          if employee
            "<a href='#{target_url}'><div class='linked-palette'>
          <div class='subcontent-header themed_text'>#{employee.full_name}</div>
          <div class='subcontent-info'>#{t("emp_no")} : #{employee.employee_number}</div>
          <div class='subcontent-info'>#{t("department")} : #{employee.employee_department.name}</div>
          <div class='subcontent-info'>#{t("leave_type")} : #{t(leave_type)}</div></div></a>".html_safe
          else
            employee = ArchivedEmployee.find_by_former_id(self.employee_id)
            "<div class='subcontent-header'>#{employee.full_name} (#{t("deleted_employee")})</div>
          <div class='subcontent-info'>#{t("leave_type")} : #{t(leave_type)}</div>".html_safe
          end
        end
      end
    end
  end

  module ExamPaletteText
    def self.included(base)
      base.class_eval do
        def examinations_palette_text
          exam_group = self.exam_group
          u=Authorization.current_user
          if(u.role_symbols & [:admin,:examination_control,:enter_results,:employee]).empty?
            "<div class='subcontent-header'>#{exam_group.name}</div>
          <div class='subcontent-info'>#{t("subject_text")} : #{self.subject.name} (#{self.subject.code})</div>
          <div class='subcontent-info'>#{format_date(self.start_time,:format=>:time)} - #{format_date(self.end_time,:format=>:time)}</div>
          <div class='subcontent-info'>#{t("batch")} : #{exam_group.batch.full_name}</div>".html_safe
          else
            "<a href='/batches/#{exam_group.batch_id}/exam_groups/#{exam_group.id}'><div class='linked-palette'>
          <div class='subcontent-header themed_text'>#{exam_group.name}</div>
          <div class='subcontent-info'>#{t("subject_text")} : #{self.subject.name} (#{self.subject.code})</div>
          <div class='subcontent-info'>#{format_date(self.start_time,:format=>:time)} - #{format_date(self.end_time,:format=>:time)}</div>
          <div class='subcontent-info'>#{t("batch")} : #{exam_group.batch.full_name}</div></div></a>".html_safe
          end
        end
      end
    end
  end

  module ApplyLeavePaletteText
    def self.included(base)
      base.class_eval do
        def leave_applications_palette_text
          u=Authorization.current_user
          employee = self.employee
          if employee
            if employee.reporting_manager_id == u.id
              "<a href='/employee_attendance/leave_application/#{self.id}?from=reportees_leaves'><div class='linked-palette'>
               <div class='subcontent-info'>#{EmployeeLeaveType.find(self.employee_leave_type_id).name}</div>
               <div class='subcontent-info'>#{format_date(self.start_date,:format=>:long_date)} - #{format_date(self.end_date,:format=>:long_date)}</div>
               <div class='subcontent-header themed_text'>#{employee.full_name}</div>
               <div class='subcontent-info'>#{t("emp_no")} : #{employee.employee_number}</div>
               <div class='subcontent-info'>#{t("department")} : #{employee.employee_department.name}</div></div></a>".html_safe
            else
              "<div class='subcontent-info'>#{EmployeeLeaveType.find(self.employee_leave_type_id).name}</div>
               <div class='subcontent-info'>#{format_date(self.start_date,:format=>:long_date)} - #{format_date(self.end_date,:format=>:long_date)}</div>
               <div class='subcontent-header'>#{employee.full_name}</div>
               <div class='subcontent-info'>#{t("emp_no")} : #{employee.employee_number}</div>
               <div class='subcontent-info'>#{t("department")} : #{employee.employee_department.name}</div>".html_safe
            end
          else
            employee = ArchivedEmployee.find_by_former_id(self.employee_id)
            "<div class='subcontent-info'>#{EmployeeLeaveType.find(self.employee_leave_type_id).name}</div>
          <div class='subcontent-info'>#{format_date(self.start_date,:format=>:long_date)} - #{format_date(self.end_date,:format=>:long_date)}</div>
          <div class='subcontent-header'>#{employee.full_name} (#{t("deleted_employee")})</div>".html_safe
          end
        end

        #        def employees_on_leave_palette_text
        #          employee = self.employee
        #          "<div class='subcontent-info'>#{EmployeeLeaveType.find(self.employee_leave_type_id).name}</div>
        #          <div class='subcontent-info'>#{self.start_date.strftime("%d %B, %Y")} - #{self.end_date.strftime("%d %B, %Y")}</div>
        #         <div class='subcontent-header themed_text'>#{employee.full_name}</div>
        #          <div class='subcontent-info'>Employee No. : #{employee.employee_number}</div>
        #          <div class='subcontent-info'>Department : #{employee.employee_department.name}</div>#".html_safe
        #        end
      end
    end
  end

  module SmsPaletteText
    def self.included(base)
      base.class_eval do
        def sms_sent_palette_text
          message = self.sms_message
          "<a href='/sms/show_sms_logs/#{message.id}'><div class='linked-palette'>
          <div class='subcontent-header themed_text'>#{self.mobile}</div>
          <div class='subcontent-info'>#{CGI.unescape(message.body)}</div>
          <div class='subcontent-footer'>
          <div class='footer-date'>#{t("sent_at")} #{format_date(FedenaTimeSet.current_time_to_local_time(self.created_at),:format=>:time)}</div>
          </div></div></a>".html_safe
        end
      end
    end
  end

  module FinancePaletteText
    def self.included(base)
      base.class_eval do
        def finance_palette_text
          total_income = FinanceTransaction.sum(:amount, :joins => "INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
            :conditions=>["(fa.id IS NULL OR fa.is_deleted = false) AND transaction_date = ? AND category_id IN (select id from finance_transaction_categories where is_income = 1)",self.transaction_date])
          total_income += AdvanceFeeCollection.sum(:fees_paid, :joins => [:advance_fee_transaction_receipt_record], 
            :conditions => ["advance_fee_collections.date_of_advance_fee_payment = ?", self.transaction_date])
          total_expense = FinanceTransaction.sum(:amount, :conditions=>["transaction_date = ? AND category_id IN (select id from finance_transaction_categories where is_income = 0)",self.transaction_date])
          currency = Configuration.currency
          "<a href='/finance/update_monthly_report?start_date=#{self.transaction_date.strftime("%Y-%m-%d")}&end_date=#{self.transaction_date.strftime("%Y-%m-%d")}'><div class='linked-palette'>
          <div class='subcontent-header'>
          <span class='header-left themed_text'>#{t("total_income")} (#{currency}) : </span><span class='header-right'>#{FedenaPrecision.set_and_modify_precision(total_income)}</span>
          </div>
          <div class='subcontent-header'>
          <span class='header-left themed_text'>#{t("total_expense")} (#{currency}) : </span><span class='header-right'>#{FedenaPrecision.set_and_modify_precision(total_expense)}</span>
          </div></div></a>".html_safe
        end
      end
    end
  end

  module TimetablePaletteText
    def self.included(base)
      base.class_eval do
        def timetable_palette_text
          u=Authorization.current_user
          if (u.role_symbols & [:admin,:manage_timetable,:timetable_view]).present?
            "<a href='/timetable/view'><div class='linked-palette'>
          <div class='subcontent-info'>#{format_date(self.class_timing.start_time,:format=>:time)} - #{format_date(self.class_timing.end_time,:format=>:time)}</div>
          <div class='subcontent-header themed_text'>#{self.assigned_name}</div>
          <div class='subcontent-info'>#{self.batch.full_name}</div></div></a>".html_safe
          elsif u.student?
            "<a href='/timetable/student_view/#{u.student_record.id}'><div class='linked-palette'>
          <div class='subcontent-info'>#{format_date(self.class_timing.start_time,:format=>:time)} - #{format_date(self.class_timing.end_time,:format=>:time)}</div>
          <div class='subcontent-header themed_text'>#{self.assigned_name}</div>
          <div class='subcontent-info'>#{self.batch.full_name}</div></div></a>".html_safe
          elsif u.parent?
            "<a href='/timetable/student_view/#{u.guardian_entry.current_ward_id}'><div class='linked-palette'>
          <div class='subcontent-info'>#{format_date(self.class_timing.start_time,:format=>:time)} - #{format_date(self.class_timing.end_time,:format=>:time)}</div>
          <div class='subcontent-header themed_text'>#{self.assigned_name}</div>
          <div class='subcontent-info'>#{self.batch.full_name}</div></div></a>".html_safe
          elsif u.employee?
            "<a href='/timetable/employee_timetable/#{u.employee_record.id}'><div class='linked-palette'>
          <div class='subcontent-info'>#{format_date(self.class_timing.start_time,:format=>:time)} - #{format_date(self.class_timing.end_time,:format=>:time)}</div>
          <div class='subcontent-header themed_text'>#{self.assigned_name}</div>
          <div class='subcontent-info'>#{self.batch.full_name}</div></div></a>".html_safe
          end
        end
      end
    end
  end

  module TaskPaletteText
    def self.included(base)
      base.class_eval do
        def tasks_due_palette_text
          "<a href='/tasks/#{self.id}'><div class='linked-palette'>
           <div class='subcontent-header themed_text'>#{self.title}</div>
           <div class='subcontent-footer'>
            <div class='footer-date'>#{t("posted_by")} #{self.user.present? ? self.user.full_name : t('deleted_user')}</div>
            <div class='footer-comment'>
             <span class='footer-comment-icon'></span> #{self.task_comments.count}
            </div>
           </div></div></a>".html_safe
        end
      end
    end
  end

  module DiscussionPaletteText
    def self.included(base)
      base.class_eval do
        def discussions_palette_text
          "<a href='/groups/#{self.group_id}/group_posts/#{self.id}'><div class='linked-palette'>
           <div class='subcontent-header themed_text'>#{self.post_title}</div>
           <div class='subcontent-info'>#{t("group_text")} : #{self.group.group_name}</div>
           <div class='subcontent-footer'>
            <div class='footer-date'>#{t("posted_by")} #{self.user.present? ? self.user.full_name : t("deleted_user")}</div>
            <div class='footer-comment'>
             <span class='footer-comment-icon'></span> #{self.group_post_comments.count}
            </div>
           </div></div></a>".html_safe
        end
      end
    end
  end

  module BlogPaletteText
    def self.included(base)
      base.class_eval do
        def blogs_palette_text
          bl = self.blog
          u = "#{self.title.gsub('/','%2F').gsub('.','%20S').gsub('?',"%2G")}-#{self.id}"
          "<a href='/blogs/#{bl.user_id}/#{URI.encode(u)}'><div class='linked-palette'>
           <div class='subcontent-header themed_text'>#{self.title}</div>
           <div class='subcontent-info'>#{t("blog_text")} : #{bl.name}</div>
           <div class='subcontent-footer'>
            <div class='footer-date'>#{t("posted_by")} #{bl.user.present? ? bl.user.full_name : t('deleted_user')}</div>
            <div class='footer-comment'>
             <span class='footer-comment-icon'></span> #{self.blog_comments.count}
            </div>
           </div></div></a>".html_safe
        end
      end
    end
  end

  module PollPaletteText
    def self.included(base)
      base.class_eval do
        def polls_palette_text
          already_voted = PollVote.find_by_poll_question_id_and_user_id(self.id,Authorization.current_user.id)
          if already_voted.nil?
            "<a href='/poll_questions/#{self.id}/voting'><div class='linked-palette'>
           <div class='subcontent-header themed_text'>#{self.title}</div>
           <div class='subcontent-info'>#{t("votes")} : #{self.poll_votes.count}</div>
           <div class='subcontent-footer'>
            <div class='footer-date'>#{t("created_by")} #{self.poll_creator.present? ? self.poll_creator.full_name : t('deleted_user')}</div>
           </div></div></a>".html_safe
          else
            "<a href='/poll_questions/#{self.id}'><div class='linked-palette'>
           <div class='subcontent-header themed_text'>#{self.title}</div>
           <div class='subcontent-info'>#{t("votes")} : #{self.poll_votes.count}</div>
           <div class='subcontent-footer'>
            <div class='footer-date'>#{t("created_by")} #{self.poll_creator.present? ? self.poll_creator.full_name : t('deleted_user')}</div>
           </div></div></a>".html_safe
          end
        end
      end
    end
  end

  module LibraryPaletteText
    def self.included(base)
      base.class_eval do
        def book_return_due_palette_text
          u=Authorization.current_user
          book = self.book
          if u.admin?
            "<a href='/books/#{book.id}'><div class='linked-palette'>
          <div class='subcontent-info'>#{t("book_no")} : #{book.book_number}</div>
          <div class='subcontent-header themed_text'>#{book.title}</div>
          <div class='subcontent-info'>#{t("author")} : #{book.author}</div>
          <div class='subcontent-footer'>
          <div class='footer-date'>#{t("issued_on")} #{format_date(self.issue_date,:format=>:long_date)}</div>
          </div></div></a>".html_safe
          elsif u.student?
            "<a href='/library/student_library_details/#{u.student_record.id}'><div class='linked-palette'>
          <div class='subcontent-info'>#{t("book_no")} : #{book.book_number}</div>
          <div class='subcontent-header themed_text'>#{book.title}</div>
          <div class='subcontent-info'>#{t("author")} : #{book.author}</div>
          <div class='subcontent-footer'>
          <div class='footer-date'>#{t("issued_on")} #{format_date(self.issue_date,:format=>:long_date)}</div>
          </div></div></a>".html_safe
          elsif u.employee?
            "<a href='/library/employee_library_details/#{u.employee_record.id}'><div class='linked-palette'>
          <div class='subcontent-info'>#{t("book_no")} : #{book.book_number}</div>
          <div class='subcontent-header themed_text'>#{book.title}</div>
          <div class='subcontent-info'>#{t("author")} : #{book.author}</div>
          <div class='subcontent-footer'>
          <div class='footer-date'>#{t("issued_on")} #{format_date(self.issue_date,:format=>:long_date)}</div>
          </div></div></a>".html_safe
          else
            "<div class='subcontent-info'>#{t("book_no")} : #{book.book_number}</div>
          <div class='subcontent-header'>#{book.title}</div>
          <div class='subcontent-info'>#{t("author")} : #{book.author}</div>
          <div class='subcontent-footer'>
          <div class='footer-date'>#{t("issued_on")} #{format_date(self.issue_date,:format=>:long_date)}</div>
          </div>".html_safe
          end
        end
      end
    end
  end

  module OnlineMeetingPaletteText
    def self.included(base)
      base.class_eval do
        def online_meetings_palette_text
          "<a href='/online_meeting_rooms/#{self.id}'><div class='linked-palette'>
          <div class='subcontent-header themed_text'>#{self.name}</div>
          <div class='subcontent-info'>#{t("scheduled_on")} : #{format_date(self.scheduled_on,:format=>:time)}</div>
          <div class='subcontent-info'>#{t("server")} : #{self.server.name}</div>
          <div class='subcontent-footer'>
          <div class='footer-date'>#{t("created_by")} #{self.user.present? ? self.user.full_name : t('deleted_user')}</div>
          </div></div></a>".html_safe
        end
      end
    end
  end

  module PlacementPaletteText
    def self.included(base)
      base.class_eval do
        def placements_palette_text
          u=Authorization.current_user
          if u.parent?
            "<div class='subcontent-header themed_text'>#{self.title}</div>
          <div class='subcontent-info'>#{t("company")} : #{self.company}</div></div></a>".html_safe
          else
            "<a href='/placementevents/#{self.id}'><div class='linked-palette'>
          <div class='subcontent-header themed_text'>#{self.title}</div>
          <div class='subcontent-info'>#{t("company")} : #{self.company}</div></div></a>".html_safe
          end
        end
      end
    end
  end

  module BirthdayPaletteText
    def self.included(base)
      base.class_eval do
        def birthdays_palette_text
          u=Authorization.current_user
          if self.admin? or self.employee?
            employee = self.employee_record
            if employee and employee.photo.file?
              photo_path = employee.photo.url(:original, false)
            else
              photo_path = "images/HR/default_employee.png"
            end
            if (u.role_symbols & [:admin,:manage_users,:hr_basics,:employee_search]).present?
              "<a href='/employee/profile/#{employee.id}'><div class='birthday-subcontent linked-palette'>
            <div class='birthday-image'>
            <img src='#{photo_path}' alt='#{employee.full_name}' class='image-icon'>
            </div>
            <div class='birthday-text'>
            <div class='subcontent-header themed_text'>#{employee.full_name}</div>
            <div class='subcontent-info'>#{t("department")} : #{employee.employee_department.name}</div>
            </div></div></a>".html_safe
            else
              "<div class='birthday-subcontent'>
            <div class='birthday-image'>
            <img src='#{photo_path}' alt='#{employee.full_name}' class='image-icon'>
            </div>
            <div class='birthday-text'>
            <div class='subcontent-header'>#{employee.full_name}</div>
            <div class='subcontent-info'>#{t("department")} : #{employee.employee_department.name}</div>
            </div></div>".html_safe
            end
          else
            student = self.student_record
            if student.photo.file?
              photo_path = student.photo.url(:original, false)
            else
              photo_path = "images/master_student/profile/default_student.png"
            end
            if (u.role_symbols & [:admin,:manage_course_batch,:admission,:students_control,:student_view,:manage_users]).present?
              "<a href='/student/profile/#{student.id}'><div class='birthday-subcontent linked-palette'>
            <div class='birthday-image'>
            <img src='#{photo_path}' alt='#{student.full_name}' class='image-icon'>
            </div>
            <div class='birthday-text'>
            <div class='subcontent-header themed_text'>#{student.full_name}</div>
            <div class='subcontent-info'>#{t("batch")} : #{student.batch.full_name}</div>
            </div></div></a>".html_safe
            else
              "<div class='birthday-subcontent'>
            <div class='birthday-image'>
            <img src='#{photo_path}' alt='#{student.full_name}' class='image-icon'>
            </div>
            <div class='birthday-text'>
            <div class='subcontent-header'>#{student.full_name}</div>
            <div class='subcontent-info'>#{t("batch")} : #{student.batch.full_name}</div>
            </div></div>".html_safe
            end
          end
        end
      end
    end
  end

  module GalleryPaletteText
    def self.included(base)
      base.class_eval do
        def photos_added_palette_text
          "<a target='_blank' href='#{self.photo.url(:original, false)}'><div class='birthday-subcontent linked-palette'>
            <div class='gallery-image'>
            <img src='#{self.photo.url(:thumb, false)}' alt='#{self.name}' class='gallery-icon'>
            </div>
            <div class='gallery-text'>
            <div class='subcontent-header themed_text'>#{self.name}</div>
            <div class='subcontent-info'>#{t("album")} : #{self.gallery_category.name}</div>
            </div></div></a>".html_safe
        end
      end
    end
  end

end
