#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

module AutosuggestMenuHelper
  DEFAULT = [
    {:menu_type => 'link' ,:label => 'autosuggest_menu.student_admission',:value => {:controller => :student,:action => :admission1}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.employee_admission',:value =>{:controller => :employee,:action => :admission1}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.exam',:value =>{:controller => :exam,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.set_grading_levels',:value =>{:controller => :grading_levels,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.exam_management',:value =>{:controller => :course_exam_groups,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.additional_exams',:value =>{:controller => :additional_exam,:action => :create_additional_exam}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.exam_wise_report',:value =>{:controller => :exam,:action => :exam_wise_report}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.subject_wise_report',:value =>{:controller => :exam,:action => :subject_wise_report}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.grouped_exam_report',:value =>{:controller => :exam,:action => :grouped_exam_report}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.news',:value =>{:controller => :news,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.event',:value =>{:controller => :event,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.view_news',:value =>{:controller => :news,:action => :all}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.add_news',:value =>{:controller => :news,:action => :add}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.employee',:value =>{:controller => :employee,:action => :hr}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.employee_settings',:value =>{:controller => :employee,:action => :settings}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.employee_subject_association',:value =>{:controller => :employee,:action => :subject_assignment}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.employee_leave_management',:value =>{:controller => :employee,:action => :employee_attendance}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.list_leave_type',:value =>{:controller => :employee_attendance,:action => :list_leave_types}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.list_leave_groups',:value =>{:controller => :leave_groups,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.reset_logs',:value =>{:controller => :employee_attendance,:action => :reset_logs}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.reset_leaves',:value =>{:controller => :employee_attendance,:action => :reset_leaves}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.reset_all_employees',:value =>{:controller => :employee_attendance,:action => :reset_all_employees}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.add_leave_type',:value =>{:controller => :employee_attendance,:action => :add_leave_types}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.leave_applications',:value =>{:controller => :employee_attendance,:action => :leave_applications}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.employee_attendance_register',:value =>{:controller => :employee_attendances,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.employee_attendance_report',:value =>{:controller => :employee_attendance,:action => :report}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.reset_leave',:value =>{:controller => :employee_attendance,:action => :reset_logs}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.empolyee_payslip',:value =>{:controller => :employee,:action => :payroll_and_payslips}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.finance',:value =>{:controller => :finance,:action => :index}},
    
    {:menu_type => 'link' ,:label => 'autosuggest_menu.fee_general_settings',:value =>{:controller => :finance_settings,:action => :fee_general_settings}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.fee_settings',:value =>{:controller => :finance_settings,:action => :fee_settings}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.manage_fee_accounts',:value =>{:controller => :fee_accounts,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.manage_receipt_sets',:value =>{:controller => :receipt_sets,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.manage_receipt_templates',:value =>{:controller => :receipt_templates,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.pdf_settings',:value =>{:controller => :finance_settings,:action => :receipt_pdf_settings}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.printer_settings',:value =>{:controller => :finance_settings,:action => :receipt_print_settings}},
    
    {:menu_type => 'link' ,:label => 'autosuggest_menu.manage_fees',:value =>{:controller => :finance,:action => :fees_index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.fee_collection',:value =>{:controller => :finance,:action => :fee_collection}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.fee_submission_by_batch',:value =>{:controller => :finance,:action => :fees_submission_batch}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.fee_submission_for_each_student',:value =>{:controller => :finance,:action => :fees_student_search,:target_action=>:student_wise_fee_payment,:target_controller=>:finance}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.finance_categories',:value =>{:controller => :finance,:action => :categories}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.transactions',:value =>{:controller => :finance,:action => :transactions}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.add_expense',:value =>{:controller => :finance,:action => :expense_create}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.expense_list',:value =>{:controller => :finance,:action => :expense_list}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.add_income',:value =>{:controller => :finance,:action => :income_create}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.income_list',:value =>{:controller => :finance,:action => :income_list}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.transaction_report',:value =>{:controller => :finance,:action => :monthly_report}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.compare_transactions',:value =>{:controller => :finance,:action => :compare_report}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.donations',:value =>{:controller => :finance,:action => :donation}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.donors',:value =>{:controller => :finance,:action => :donors}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.automatic_transactions',:value =>{:controller => :finance,:action => :automatic_transactions}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.view_payslip',:value =>{:controller => :finance,:action => :view_monthly_payslip}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.asset',:value =>{:controller => :finance,:action => :asset}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.view_assets',:value =>{:controller => :finance,:action => :view_asset}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.liability',:value =>{:controller => :finance,:action => :liability}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.view_liability',:value =>{:controller => :finance,:action => :view_liability}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.manage_users',:value =>{:controller => :user,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.view_users',:value =>{:controller => :user,:action => :all}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.add_users',:value =>{:controller => :user,:action => :create}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.timetable',:value =>{:controller => :timetable,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.create_timetable',:value =>{:controller => :timetable,:action => :select_class2}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.set_class_timings',:value =>{:controller => :class_timing_sets,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.view_timetables',:value =>{:controller => :timetable,:action => :view}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.institutional_timetable',:value =>{:controller => :timetable,:action => :timetable}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.create_weekdays',:value =>{:controller => :weekday,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.settings',:value =>{:controller => :configuration,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.manage_course',:value =>{:controller => :courses,:action => :manage_course}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.manage_batch',:value =>{:controller => :courses,:action => :manage_batches}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.add_course',:value =>{:controller => :courses,:action => :new}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.batch_transfers',:value =>{:controller => :batch_transfers,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.manage_student_category',:value =>{:controller => :student,:action => :categories}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.manage_subjects',:value =>{:controller => :subjects,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.general_settings',:value =>{:controller => :configuration,:action => :settings}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.add_admission_additional_detail',:value =>{:controller => :student,:action => :add_additional_details}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.student_attendance',:value =>{:controller => :student_attendance,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.attendance_register',:value =>{:controller => :attendances,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.attendance_report',:value =>{:controller => :attendance_reports,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.view_students',:value =>{:controller => :student,:action => :view_all}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.student_advanced_search',:value =>{:controller => :student,:action => :advanced_search}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.create_fees',:value =>{:controller => :finance,:action => :master_fees}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.fee_defaulters',:value =>{:controller => :finance,:action => :fees_defaulters}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.fee_structure',:value =>{:controller => :finance,:action => :fees_student_structure_search}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.messages',:value =>{:controller => :reminder,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.sent_messages',:value =>{:controller => :reminder,:action => :sent_reminder}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.create_messages',:value =>{:controller => :reminder,:action => :create_reminder}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.change_password',:value =>{:controller => :user,:action => :change_password}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.employee_advanced_search',:value =>{:controller => :employee,:action => :advanced_search}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.view_employees',:value =>{:controller => :employee,:action => :view_all}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.transfer_certificate',:value =>{:controller => :tc_templates,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.student_document_manager',:value =>{:controller => :student_document_categories,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.timetable_settings', :value =>{:controller => :timetable,:action => :settings}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.feature_access_settings', :value =>{:controller => :feature_access_settings,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.gradebook', :value =>{:controller => :gradebooks,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.academic_years_text', :value =>{:controller => :academic_years,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.exam_planner', :value =>{:controller => :assessment_plans,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.manage_gradebook', :value =>{:controller => :gradebooks,:action => :exam_management}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.custom_words_text', :value =>{:controller => :custom_words,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.gradebook_reports', :value =>{:controller => :gradebook_reports,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.certificates', :value =>{:controller => :certificate_templates,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.id_cards', :value =>{:controller => :id_card_templates,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.subjects_center_text', :value =>{:controller => :subjects_center,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.gradebook_remark_bank', :value =>{:controller => :remark_banks,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.attendance_label', :value =>{:controller => :attendance_labels,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.leave_process_settings', :value =>{:controller => :leave_years,:action => :leave_process_settings}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.leave_years', :value =>{:controller => :leave_years,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.autocredit_setting', :value =>{:controller => :leave_years,:action => :autocredit_setting}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.credit_date_setting', :value =>{:controller => :leave_years,:action => :credit_date_setting}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.credit_logs', :value =>{:controller => :employee_attendance,:action => :credit_logs}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.user_groups', :value =>{:controller => :user_groups,:action => :index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.advance_fees', :value =>{:controller => :advance_payment_fees,:action => :advance_fees_index}},
    {:menu_type => 'link' ,:label => 'autosuggest_menu.advance_fees_report', :value =>{:controller => :advance_payment_fees,:action => :report_index}}
  ]

  def autosuggest_menuitems
    Rails.cache.fetch("user_autocomplete_menu#{session[:user_id]}"){
      default = DEFAULT
      menu_items = accessible_routes((default + FedenaPlugin::ADDITIONAL_LINKS[:autosuggest_menuitems]).flatten)
      menu_items.to_json
    }
  end

  def accessible_routes (routes)
    menu_items = []
    Authorization::Engine.instance.accessible_routes(routes).each do |plugin_menu_item|
      menu_items << {
        :menu_type => plugin_menu_item[:menu_type],
        :label => t(plugin_menu_item[:label]),
        :value => url_for(plugin_menu_item[:value])
      }
    end
    menu_items
  end

  def allowed_routes (routes)
    menu_items = []
    Authorization::Engine.instance.allowed_routes(routes).each do |plugin_menu_item|
      menu_items << {
        :menu_type => plugin_menu_item[:menu_type],
        :label => t(plugin_menu_item[:label]),
        :value => url_for(plugin_menu_item[:value])
      }
    end
    menu_items
  end

end
