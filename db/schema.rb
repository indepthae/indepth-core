# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 201812191119180) do

  create_table "academic_years", :force => true do |t|
    t.string   "name"
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "is_active",  :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "academic_years", ["school_id"], :name => "index_academic_years_on_school_id", :limit => {"school_id"=>nil}

  create_table "activity_assessments", :force => true do |t|
    t.integer  "assessment_group_batch_id"
    t.integer  "assessment_activity_profile_id"
    t.integer  "assessment_activity_id"
    t.boolean  "marks_added",                    :default => false
    t.integer  "submission_status"
    t.boolean  "edited",                         :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "mark_entry_locked",              :default => false
    t.boolean  "unlocked",                       :default => false
    t.integer  "school_id"
  end

  add_index "activity_assessments", ["assessment_activity_id"], :name => "index_activity_assessments_on_assessment_activity_id", :limit => {"assessment_activity_id"=>nil}
  add_index "activity_assessments", ["assessment_activity_profile_id"], :name => "index_activity_assessments_on_assessment_activity_profile_id", :limit => {"assessment_activity_profile_id"=>nil}
  add_index "activity_assessments", ["assessment_group_batch_id"], :name => "index_activity_assessments_on_assessment_group_batch_id", :limit => {"assessment_group_batch_id"=>nil}
  add_index "activity_assessments", ["marks_added"], :name => "index_activity_assessments_on_marks_added", :limit => {"marks_added"=>nil}
  add_index "activity_assessments", ["school_id"], :name => "index_activity_assessments_on_school_id", :limit => {"school_id"=>nil}

  create_table "additional_charges", :force => true do |t|
    t.string   "name"
    t.decimal  "amount",       :precision => 15, :scale => 2
    t.integer  "invoice_id"
    t.string   "invoice_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "additional_charges", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "additional_exam_groups", :force => true do |t|
    t.string  "name"
    t.integer "batch_id"
    t.string  "exam_type"
    t.boolean "is_published",     :default => false
    t.boolean "result_published", :default => false
    t.string  "students_list"
    t.date    "exam_date"
  end

  create_table "additional_exam_scores", :force => true do |t|
    t.integer  "student_id"
    t.integer  "additional_exam_id"
    t.decimal  "marks",              :precision => 7, :scale => 2
    t.integer  "grading_level_id"
    t.string   "remarks"
    t.boolean  "is_failed"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "additional_exams", :force => true do |t|
    t.integer  "additional_exam_group_id"
    t.integer  "subject_id"
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer  "maximum_marks"
    t.integer  "minimum_marks"
    t.integer  "grading_level_id"
    t.integer  "weightage",                :default => 0
    t.integer  "event_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "additional_field_options", :force => true do |t|
    t.integer  "additional_field_id"
    t.string   "field_option"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "additional_field_options", ["school_id"], :name => "index_additional_field_options_on_school_id", :limit => {"school_id"=>nil}

  create_table "additional_fields", :force => true do |t|
    t.string   "name"
    t.boolean  "status"
    t.boolean  "is_mandatory", :default => false
    t.string   "input_type"
    t.integer  "priority"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "additional_fields", ["school_id"], :name => "index_additional_fields_on_school_id", :limit => {"school_id"=>nil}

  create_table "additional_report_csvs", :force => true do |t|
    t.string   "model_name"
    t.string   "method_name"
    t.text     "parameters"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "csv_report_file_name"
    t.string   "csv_report_content_type"
    t.integer  "csv_report_file_size"
    t.datetime "csv_report_updated_at"
    t.boolean  "status",                  :default => false
    t.boolean  "is_generated",            :default => false
    t.integer  "school_id"
  end

  add_index "additional_report_csvs", ["model_name", "method_name"], :name => "index_on_method_and_model", :limit => {"method_name"=>nil, "model_name"=>nil}
  add_index "additional_report_csvs", ["school_id"], :name => "index_additional_report_csvs_on_school_id", :limit => {"school_id"=>nil}

  create_table "additional_report_pdfs", :force => true do |t|
    t.string   "model_name"
    t.string   "method_name"
    t.text     "parameters"
    t.text     "opts"
    t.string   "pdf_report_file_name"
    t.string   "pdf_report_content_type"
    t.integer  "pdf_report_file_size"
    t.datetime "pdf_report_updated_at"
    t.boolean  "status",                  :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_generated",            :default => false
    t.integer  "school_id"
  end

  add_index "additional_report_pdfs", ["school_id"], :name => "index_additional_report_pdfs_on_school_id", :limit => {"school_id"=>nil}

  create_table "additional_settings", :force => true do |t|
    t.integer  "owner_id"
    t.string   "owner_type"
    t.text     "settings"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "additional_settings", ["id", "type"], :name => "index_additional_settings_on_id_and_type", :limit => {"type"=>nil, "id"=>nil}
  add_index "additional_settings", ["owner_id", "owner_type", "type"], :name => "index_of_owner_on_setting_type", :limit => {"type"=>nil, "owner_type"=>nil, "owner_id"=>nil}
  add_index "additional_settings", ["owner_id", "owner_type"], :name => "index_additional_settings_on_owner_id_and_owner_type", :limit => {"owner_type"=>nil, "owner_id"=>nil}

  create_table "admin_users", :force => true do |t|
    t.string   "username"
    t.string   "password_salt"
    t.string   "crypted_password"
    t.string   "email"
    t.string   "full_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
    t.integer  "higher_user_id"
    t.boolean  "is_deleted",                :default => false
    t.text     "description"
    t.string   "contact_no"
    t.string   "reset_password_code"
    t.datetime "reset_password_code_until"
  end

  add_index "admin_users", ["id", "type"], :name => "index_admin_users_on_id_and_type", :limit => {"type"=>nil, "id"=>nil}
  add_index "admin_users", ["type", "is_deleted"], :name => "index_admin_users_on_type_and_is_deleted", :limit => {"type"=>nil, "is_deleted"=>nil}
  add_index "admin_users", ["type"], :name => "index_admin_users_on_type", :limit => {"type"=>nil}
  add_index "admin_users", ["username"], :name => "index_admin_users_on_username", :limit => {"username"=>nil}

  create_table "advance_fee_categories", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "financial_year_id"
    t.boolean  "online_payment_enabled", :default => true
    t.boolean  "is_enabled",             :default => true
    t.boolean  "is_deleted",             :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "advance_fee_categories", ["financial_year_id", "online_payment_enabled", "is_enabled", "is_deleted"], :name => "index_on_f_y_id_and_o_p_enabled_and_is_enabled_and_is_deleted", :limit => {"is_deleted"=>nil, "financial_year_id"=>nil, "is_enabled"=>nil, "online_payment_enabled"=>nil}
  add_index "advance_fee_categories", ["school_id"], :name => "index_advance_fee_categories_on_school_id", :limit => {"school_id"=>nil}

  create_table "advance_fee_category_batches", :force => true do |t|
    t.integer  "advance_fee_category_id"
    t.integer  "batch_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_active",               :default => true, :null => false
    t.integer  "school_id"
  end

  add_index "advance_fee_category_batches", ["advance_fee_category_id", "batch_id", "is_active"], :name => "index_on_a_f_c_id_and_batch_id_and_is_active", :limit => {"is_active"=>nil, "batch_id"=>nil, "advance_fee_category_id"=>nil}
  add_index "advance_fee_category_batches", ["school_id"], :name => "index_advance_fee_category_batches_on_school_id", :limit => {"school_id"=>nil}

  create_table "advance_fee_category_collections", :force => true do |t|
    t.integer  "advance_fee_collection_id"
    t.integer  "advance_fee_category_id"
    t.decimal  "fees_paid",                 :precision => 15, :scale => 2, :default => 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "advance_fee_category_collections", ["school_id"], :name => "index_advance_fee_category_collections_on_school_id", :limit => {"school_id"=>nil}

  create_table "advance_fee_collections", :force => true do |t|
    t.decimal  "fees_paid",                                         :precision => 15, :scale => 2
    t.string   "payment_mode"
    t.date     "date_of_advance_fee_payment"
    t.string   "reference_no"
    t.string   "payment_note"
    t.string   "bank_name"
    t.date     "cheque_date"
    t.integer  "user_id"
    t.integer  "student_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "receipt_data",                :limit => 2147483647
    t.integer  "transaction_receipt_id"
    t.integer  "batch_id"
    t.integer  "school_id"
  end

  add_index "advance_fee_collections", ["school_id"], :name => "index_advance_fee_collections_on_school_id", :limit => {"school_id"=>nil}
  add_index "advance_fee_collections", ["student_id"], :name => "index_on_student_id", :limit => {"student_id"=>nil}

  create_table "advance_fee_deductions", :force => true do |t|
    t.decimal  "amount",                 :precision => 15, :scale => 2
    t.date     "deduction_date"
    t.integer  "student_id"
    t.integer  "finance_transaction_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "advance_fee_deductions", ["school_id"], :name => "index_advance_fee_deductions_on_school_id", :limit => {"school_id"=>nil}
  add_index "advance_fee_deductions", ["student_id", "finance_transaction_id"], :name => "index_on_student_id_and_finance_transaction_id", :limit => {"finance_transaction_id"=>nil, "student_id"=>nil}

  create_table "advance_fee_transaction_receipt_records", :force => true do |t|
    t.integer  "advance_fee_collection_id"
    t.integer  "transaction_receipt_id"
    t.integer  "fee_account_id"
    t.integer  "fee_receipt_template_id"
    t.integer  "precision_count"
    t.text     "receipt_data"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "advance_fee_wallets", :force => true do |t|
    t.decimal  "amount",     :precision => 15, :scale => 2
    t.integer  "student_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "advance_fee_wallets", ["school_id"], :name => "index_advance_fee_wallets_on_school_id", :limit => {"school_id"=>nil}
  add_index "advance_fee_wallets", ["student_id"], :name => "index_on_student_id", :limit => {"student_id"=>nil}

  create_table "allocated_classrooms", :force => true do |t|
    t.integer  "classroom_allocation_id"
    t.integer  "classroom_id"
    t.integer  "subject_id"
    t.integer  "timetable_entry_id"
    t.date     "date"
    t.boolean  "is_deleted",              :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "allocated_classrooms", ["school_id"], :name => "index_allocated_classrooms_on_school_id", :limit => {"school_id"=>nil}
  add_index "allocated_classrooms", ["timetable_entry_id", "subject_id", "classroom_allocation_id", "classroom_id"], :name => "index_by_fields", :limit => {"timetable_entry_id"=>nil, "classroom_id"=>nil, "classroom_allocation_id"=>nil, "subject_id"=>nil}

  create_table "allotment_log_details", :force => true do |t|
    t.string   "name"
    t.string   "registration_no"
    t.string   "status"
    t.string   "description"
    t.integer  "registration_course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "app_frames", :force => true do |t|
    t.string   "name"
    t.string   "link"
    t.string   "client_id"
    t.text     "privilege_list"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.boolean  "new_tab",        :default => false
  end

  add_index "app_frames", ["school_id"], :name => "index_app_frames_on_school_id", :limit => {"school_id"=>nil}

  create_table "app_session_store", :force => true do |t|
    t.integer   "session_id_crc",               :null => false
    t.string    "session_id",     :limit => 32, :null => false
    t.timestamp "updated_at",                   :null => false
    t.text      "data"
  end

  add_index "app_session_store", ["session_id_crc", "session_id"], :name => "session_id", :unique => true, :limit => {"session_id_crc"=>nil, "session_id"=>nil}
  add_index "app_session_store", ["updated_at"], :name => "updated_at", :limit => {"updated_at"=>nil}

  create_table "applicant_additional_details", :force => true do |t|
    t.integer  "applicant_id"
    t.integer  "additional_field_id"
    t.string   "additional_info"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "applicant_additional_details", ["additional_field_id"], :name => "by_additional_field_id", :limit => {"additional_field_id"=>nil}
  add_index "applicant_additional_details", ["applicant_id"], :name => "by_applicant_id", :limit => {"applicant_id"=>nil}
  add_index "applicant_additional_details", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "applicant_addl_attachment_fields", :force => true do |t|
    t.string   "name"
    t.integer  "registration_course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.boolean  "is_mandatory",           :default => false
  end

  create_table "applicant_addl_attachments", :force => true do |t|
    t.integer  "school_id"
    t.integer  "applicant_id"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "attachment_updated_at"
    t.integer  "applicant_addl_attachment_field_id"
  end

  add_index "applicant_addl_attachments", ["applicant_id"], :name => "index_applicant_addl_attachments_on_applicant_id", :limit => {"applicant_id"=>nil}
  add_index "applicant_addl_attachments", ["school_id"], :name => "index_applicant_addl_attachments_on_school_id", :limit => {"school_id"=>nil}

  create_table "applicant_addl_field_groups", :force => true do |t|
    t.integer  "school_id"
    t.integer  "registration_course_id"
    t.string   "name"
    t.boolean  "is_active",              :default => true
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
  end

  add_index "applicant_addl_field_groups", ["is_active"], :name => "index_applicant_addl_field_groups_on_is_active", :limit => {"is_active"=>nil}
  add_index "applicant_addl_field_groups", ["registration_course_id"], :name => "index_applicant_addl_field_groups_on_registration_course_id", :limit => {"registration_course_id"=>nil}
  add_index "applicant_addl_field_groups", ["school_id"], :name => "index_applicant_addl_field_groups_on_school_id", :limit => {"school_id"=>nil}

  create_table "applicant_addl_field_values", :force => true do |t|
    t.integer  "school_id"
    t.integer  "applicant_addl_field_id"
    t.string   "option"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_default",              :default => false
  end

  add_index "applicant_addl_field_values", ["applicant_addl_field_id"], :name => "index_applicant_addl_field_values_on_applicant_addl_field_id", :limit => {"applicant_addl_field_id"=>nil}
  add_index "applicant_addl_field_values", ["school_id"], :name => "index_applicant_addl_field_values_on_school_id", :limit => {"school_id"=>nil}

  create_table "applicant_addl_fields", :force => true do |t|
    t.integer  "school_id"
    t.integer  "applicant_addl_field_group_id"
    t.string   "field_name"
    t.string   "field_type"
    t.boolean  "is_active",                     :default => true
    t.integer  "position"
    t.boolean  "is_mandatory",                  :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "registration_course_id"
    t.string   "section_name"
    t.integer  "custom_section_id"
    t.string   "record_type"
    t.string   "suffix"
  end

  add_index "applicant_addl_fields", ["applicant_addl_field_group_id"], :name => "index_applicant_addl_fields_on_applicant_addl_field_group_id", :limit => {"applicant_addl_field_group_id"=>nil}
  add_index "applicant_addl_fields", ["school_id"], :name => "index_applicant_addl_fields_on_school_id", :limit => {"school_id"=>nil}

  create_table "applicant_addl_values", :force => true do |t|
    t.integer  "school_id"
    t.integer  "applicant_id"
    t.integer  "applicant_addl_field_id"
    t.text     "option"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "student_additional_field_id"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.integer  "applicant_guardian_id"
    t.integer  "temp_guardian_ind"
  end

  add_index "applicant_addl_values", ["applicant_addl_field_id"], :name => "index_applicant_addl_values_on_applicant_addl_field_id", :limit => {"applicant_addl_field_id"=>nil}
  add_index "applicant_addl_values", ["applicant_id"], :name => "index_applicant_addl_values_on_applicant_id", :limit => {"applicant_id"=>nil}
  add_index "applicant_addl_values", ["school_id"], :name => "index_applicant_addl_values_on_school_id", :limit => {"school_id"=>nil}

  create_table "applicant_guardians", :force => true do |t|
    t.integer  "school_id"
    t.integer  "applicant_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "relation"
    t.string   "email"
    t.string   "office_phone1"
    t.string   "office_phone2"
    t.string   "mobile_phone"
    t.string   "office_address_line1"
    t.string   "office_address_line2"
    t.string   "city"
    t.string   "state"
    t.integer  "country_id"
    t.date     "dob"
    t.string   "occupation"
    t.string   "income"
    t.string   "education"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "applicant_guardians", ["applicant_id"], :name => "index_applicant_guardians_on_applicant_id", :limit => {"applicant_id"=>nil}
  add_index "applicant_guardians", ["school_id"], :name => "index_applicant_guardians_on_school_id", :limit => {"school_id"=>nil}

  create_table "applicant_previous_datas", :force => true do |t|
    t.integer  "school_id"
    t.integer  "applicant_id"
    t.string   "last_attended_school"
    t.string   "qualifying_exam"
    t.string   "qualifying_exam_year"
    t.string   "qualifying_exam_roll"
    t.string   "qualifying_exam_final_score"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "applicant_previous_datas", ["applicant_id"], :name => "index_applicant_previous_datas_on_applicant_id", :limit => {"applicant_id"=>nil}
  add_index "applicant_previous_datas", ["school_id"], :name => "index_applicant_previous_datas_on_school_id", :limit => {"school_id"=>nil}

  create_table "applicant_registration_settings", :force => true do |t|
    t.integer  "school_id"
    t.string   "key"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "applicant_registration_settings", ["school_id"], :name => "index_applicant_registration_settings_on_school_id", :limit => {"school_id"=>nil}

  create_table "applicant_student_addl_fields", :force => true do |t|
    t.integer  "registration_course_id"
    t.integer  "student_additional_field_id"
    t.string   "section_name"
    t.integer  "applicant_addl_field_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  create_table "applicants", :force => true do |t|
    t.integer  "school_id"
    t.string   "reg_no"
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.date     "date_of_birth"
    t.string   "address_line1"
    t.string   "address_line2"
    t.string   "city"
    t.string   "state"
    t.integer  "country_id"
    t.integer  "nationality_id"
    t.string   "pin_code"
    t.string   "phone1"
    t.string   "phone2"
    t.string   "email"
    t.string   "gender"
    t.integer  "registration_course_id"
    t.integer  "photo_file_size"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.string   "status"
    t.boolean  "has_paid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "pin_number"
    t.string   "print_token"
    t.text     "subject_ids"
    t.boolean  "is_academically_cleared"
    t.boolean  "is_financially_cleared"
    t.decimal  "amount",                  :precision => 12, :scale => 2
    t.text     "normal_subject_ids"
    t.datetime "photo_updated_at"
    t.boolean  "is_deleted",                                             :default => false
    t.integer  "batch_id"
    t.boolean  "submitted",                                              :default => true
    t.string   "blood_group"
    t.string   "birth_place"
    t.string   "language"
    t.string   "religion"
    t.integer  "student_category_id"
    t.text     "subject_amounts"
    t.integer  "student_id"
  end

  add_index "applicants", ["created_at"], :name => "index_applicants_on_created_at", :limit => {"created_at"=>nil}
  add_index "applicants", ["reg_no", "school_id"], :name => "index_applicants_on_reg_no_and_school_id", :unique => true, :limit => {"reg_no"=>nil, "school_id"=>nil}
  add_index "applicants", ["school_id"], :name => "index_applicants_on_school_id", :limit => {"school_id"=>nil}
  add_index "applicants", ["status"], :name => "index_applicants_on_status", :limit => {"status"=>nil}
  add_index "applicants", ["submitted"], :name => "index_applicants_on_submitted", :limit => {"submitted"=>nil}

  create_table "application_instructions", :force => true do |t|
    t.integer  "registration_course_id"
    t.text     "description"
    t.boolean  "skip_instructions",      :default => false
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "application_sections", :force => true do |t|
    t.integer  "registration_course_id"
    t.string   "section_name"
    t.integer  "custom_section_id"
    t.text     "section_fields"
    t.integer  "guardian_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  create_table "application_statuses", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.boolean  "is_active",            :default => true
    t.boolean  "notification_enabled", :default => false
    t.boolean  "is_default",           :default => false
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "apply_leaves", :force => true do |t|
    t.integer  "employee_id"
    t.integer  "employee_leave_type_id"
    t.boolean  "is_half_day"
    t.date     "start_date"
    t.date     "end_date"
    t.string   "reason"
    t.boolean  "approved",               :default => false
    t.boolean  "viewed_by_manager",      :default => false
    t.string   "manager_remark"
    t.integer  "approving_manager"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "apply_leaves", ["school_id"], :name => "index_apply_leaves_on_school_id", :limit => {"school_id"=>nil}

  create_table "archived_employee_additional_details", :force => true do |t|
    t.integer  "employee_id"
    t.integer  "additional_field_id"
    t.string   "additional_info"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "archived_employee_additional_details", ["school_id"], :name => "index_archived_employee_additional_details_on_school_id", :limit => {"school_id"=>nil}

  create_table "archived_employee_bank_details", :force => true do |t|
    t.integer  "employee_id"
    t.integer  "bank_field_id"
    t.string   "bank_info"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "archived_employee_bank_details", ["school_id"], :name => "index_archived_employee_bank_details_on_school_id", :limit => {"school_id"=>nil}

  create_table "archived_employee_salary_structure_components", :force => true do |t|
    t.integer  "archived_employee_salary_structure_id"
    t.integer  "payroll_category_id"
    t.string   "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "archived_employee_salary_structure_components", ["school_id"], :name => "index_archived_employee_salary_structure_components_on_school_id", :limit => {"school_id"=>nil}

  create_table "archived_employee_salary_structures", :force => true do |t|
    t.integer  "employee_id"
    t.integer  "payroll_category_id"
    t.string   "amount"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "gross_salary"
    t.string   "net_pay"
    t.integer  "revision_number"
    t.integer  "payroll_group_id"
    t.integer  "latest_revision_id"
    t.integer  "school_id"
  end

  add_index "archived_employee_salary_structures", ["school_id"], :name => "index_archived_employee_salary_structures_on_school_id", :limit => {"school_id"=>nil}

  create_table "archived_employees", :force => true do |t|
    t.integer  "employee_category_id"
    t.string   "employee_number"
    t.date     "joining_date"
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.string   "gender"
    t.string   "job_title"
    t.integer  "employee_position_id"
    t.integer  "employee_department_id"
    t.integer  "reporting_manager_id"
    t.integer  "employee_grade_id"
    t.string   "qualification"
    t.text     "experience_detail"
    t.integer  "experience_year"
    t.integer  "experience_month"
    t.boolean  "status"
    t.string   "status_description"
    t.date     "date_of_birth"
    t.string   "marital_status"
    t.integer  "children_count"
    t.string   "father_name"
    t.string   "mother_name"
    t.string   "husband_name"
    t.string   "blood_group"
    t.integer  "nationality_id"
    t.string   "home_address_line1"
    t.string   "home_address_line2"
    t.string   "home_city"
    t.string   "home_state"
    t.integer  "home_country_id"
    t.string   "home_pin_code"
    t.string   "office_address_line1"
    t.string   "office_address_line2"
    t.string   "office_city"
    t.string   "office_state"
    t.integer  "office_country_id"
    t.string   "office_pin_code"
    t.string   "office_phone1"
    t.string   "office_phone2"
    t.string   "mobile_phone"
    t.string   "home_phone"
    t.string   "email"
    t.string   "fax"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.binary   "photo_data",             :limit => 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "photo_file_size"
    t.integer  "former_id"
    t.integer  "user_id"
    t.datetime "photo_updated_at"
    t.integer  "school_id"
    t.date     "last_reset_date"
    t.date     "date_of_leaving"
    t.date     "last_credit_date"
    t.string   "library_card"
  end

  add_index "archived_employees", ["employee_department_id"], :name => "index_archived_employees_on_employee_department_id", :limit => {"employee_department_id"=>nil}
  add_index "archived_employees", ["employee_number", "school_id"], :name => "employee_number_unique_index", :unique => true, :limit => {"school_id"=>nil, "employee_number"=>nil}
  add_index "archived_employees", ["former_id"], :name => "index_archived_employees_on_former_id", :limit => {"former_id"=>nil}
  add_index "archived_employees", ["school_id"], :name => "index_archived_employees_on_school_id", :limit => {"school_id"=>nil}

  create_table "archived_exam_scores", :force => true do |t|
    t.integer  "student_id"
    t.integer  "exam_id"
    t.decimal  "marks",            :precision => 7, :scale => 2
    t.integer  "grading_level_id"
    t.string   "remarks"
    t.boolean  "is_failed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "archived_exam_scores", ["school_id"], :name => "index_archived_exam_scores_on_school_id", :limit => {"school_id"=>nil}
  add_index "archived_exam_scores", ["student_id", "exam_id"], :name => "index_archived_exam_scores_on_student_id_and_exam_id", :limit => {"student_id"=>nil, "exam_id"=>nil}

  create_table "archived_guardians", :force => true do |t|
    t.integer  "ward_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "relation"
    t.string   "email"
    t.string   "office_phone1"
    t.string   "office_phone2"
    t.string   "mobile_phone"
    t.string   "office_address_line1"
    t.string   "office_address_line2"
    t.string   "city"
    t.string   "state"
    t.integer  "country_id"
    t.date     "dob"
    t.string   "occupation"
    t.string   "income"
    t.string   "education"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "former_user_id"
    t.integer  "former_id"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.integer  "familyid",             :limit => 8
    t.integer  "school_id"
  end

  add_index "archived_guardians", ["familyid"], :name => "index_archived_guardians_on_familyid", :limit => {"familyid"=>nil}
  add_index "archived_guardians", ["school_id"], :name => "index_archived_guardians_on_school_id", :limit => {"school_id"=>nil}

  create_table "archived_students", :force => true do |t|
    t.string   "admission_no"
    t.string   "class_roll_no"
    t.date     "admission_date"
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.integer  "batch_id"
    t.date     "date_of_birth"
    t.string   "gender"
    t.string   "blood_group"
    t.string   "birth_place"
    t.integer  "nationality_id"
    t.string   "language"
    t.string   "religion"
    t.integer  "student_category_id"
    t.string   "address_line1"
    t.string   "address_line2"
    t.string   "city"
    t.string   "state"
    t.string   "pin_code"
    t.integer  "country_id"
    t.string   "phone1"
    t.string   "phone2"
    t.string   "email"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.binary   "photo_data",                     :limit => 16777215
    t.string   "status_description"
    t.boolean  "is_active",                                          :default => true
    t.boolean  "is_deleted",                                         :default => false
    t.integer  "immediate_contact_id"
    t.boolean  "is_sms_enabled",                                     :default => true
    t.integer  "former_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "photo_file_size"
    t.integer  "user_id"
    t.boolean  "is_email_enabled",                                   :default => true
    t.integer  "sibling_id"
    t.datetime "photo_updated_at"
    t.date     "date_of_leaving"
    t.boolean  "former_has_paid_fees"
    t.string   "roll_number"
    t.boolean  "former_has_paid_fees_for_batch"
    t.integer  "school_id"
    t.string   "library_card"
    t.integer  "familyid",                       :limit => 8
  end

  add_index "archived_students", ["admission_no", "school_id"], :name => "admission_no_unique_index", :unique => true, :limit => {"admission_no"=>nil, "school_id"=>nil}
  add_index "archived_students", ["batch_id"], :name => "index_archived_students_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "archived_students", ["familyid"], :name => "index_archived_students_on_familyid", :limit => {"familyid"=>nil}
  add_index "archived_students", ["former_id"], :name => "index_archived_students_on_former_id", :limit => {"former_id"=>nil}
  add_index "archived_students", ["school_id"], :name => "index_archived_students_on_school_id", :limit => {"school_id"=>nil}
  add_index "archived_students", ["user_id"], :name => "index_archived_students_on_user_id", :limit => {"user_id"=>nil}

  create_table "archived_transports", :force => true do |t|
    t.integer  "receiver_id"
    t.string   "receiver_type"
    t.integer  "academic_year_id"
    t.integer  "mode"
    t.integer  "pickup_route_id"
    t.integer  "drop_route_id"
    t.integer  "pickup_stop_id"
    t.integer  "drop_stop_id"
    t.decimal  "bus_fare",         :precision => 15, :scale => 4
    t.boolean  "auto_update_fare"
    t.boolean  "remove_fare"
    t.date     "applied_from"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "archived_transports", ["academic_year_id"], :name => "index_archived_transports_on_academic_year_id", :limit => {"academic_year_id"=>nil}
  add_index "archived_transports", ["drop_route_id"], :name => "index_archived_transports_on_drop_route_id", :limit => {"drop_route_id"=>nil}
  add_index "archived_transports", ["drop_stop_id"], :name => "index_archived_transports_on_drop_stop_id", :limit => {"drop_stop_id"=>nil}
  add_index "archived_transports", ["pickup_route_id", "drop_route_id"], :name => "index_on_route", :limit => {"drop_route_id"=>nil, "pickup_route_id"=>nil}
  add_index "archived_transports", ["pickup_route_id"], :name => "index_archived_transports_on_pickup_route_id", :limit => {"pickup_route_id"=>nil}
  add_index "archived_transports", ["pickup_stop_id"], :name => "index_archived_transports_on_pickup_stop_id", :limit => {"pickup_stop_id"=>nil}
  add_index "archived_transports", ["receiver_type", "receiver_id"], :name => "index_on_r_type_id", :limit => {"receiver_id"=>nil, "receiver_type"=>nil}
  add_index "archived_transports", ["school_id"], :name => "index_archived_transports_on_school_id", :limit => {"school_id"=>nil}

  create_table "asl_scores", :force => true do |t|
    t.integer  "student_id"
    t.integer  "exam_id"
    t.decimal  "speaking",    :precision => 7, :scale => 2
    t.decimal  "listening",   :precision => 7, :scale => 2
    t.decimal  "final_score", :precision => 7, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "asl_scores", ["school_id"], :name => "index_asl_scores_on_school_id", :limit => {"school_id"=>nil}

  create_table "assessment_activities", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "assessment_activity_profile_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "assessment_activities", ["assessment_activity_profile_id"], :name => "index_assessment_activities_on_assessment_activity_profile_id", :limit => {"assessment_activity_profile_id"=>nil}
  add_index "assessment_activities", ["school_id"], :name => "index_assessment_activities_on_school_id", :limit => {"school_id"=>nil}

  create_table "assessment_activity_profiles", :force => true do |t|
    t.string   "name"
    t.string   "display_name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "assessment_activity_profiles", ["school_id"], :name => "index_assessment_activity_profiles_on_school_id", :limit => {"school_id"=>nil}

  create_table "assessment_attribute_profiles", :force => true do |t|
    t.string   "name"
    t.string   "display_name"
    t.string   "description"
    t.string   "formula"
    t.decimal  "maximum_marks",         :precision => 10, :scale => 2
    t.decimal  "maximum_subject_marks", :precision => 10, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "assessment_attribute_profiles", ["school_id"], :name => "index_assessment_attribute_profiles_on_school_id", :limit => {"school_id"=>nil}

  create_table "assessment_attributes", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "assessment_attribute_profile_id"
    t.decimal  "maximum_marks",                   :precision => 10, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "assessment_attributes", ["assessment_attribute_profile_id"], :name => "index_assessment_attributes_on_assessment_attribute_profile_id", :limit => {"assessment_attribute_profile_id"=>nil}
  add_index "assessment_attributes", ["school_id"], :name => "index_assessment_attributes_on_school_id", :limit => {"school_id"=>nil}

  create_table "assessment_dates", :force => true do |t|
    t.integer  "batch_id"
    t.integer  "assessment_group_id"
    t.date     "start_date"
    t.date     "end_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "assessment_dates", ["school_id"], :name => "index_assessment_dates_on_school_id", :limit => {"school_id"=>nil}

  create_table "assessment_group_batches", :force => true do |t|
    t.integer  "assessment_group_id"
    t.integer  "batch_id"
    t.integer  "course_id"
    t.boolean  "marks_added",          :default => false
    t.boolean  "result_published",     :default => false
    t.boolean  "report_generated",     :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "submission_status"
    t.date     "mark_entry_last_date"
    t.integer  "school_id"
  end

  add_index "assessment_group_batches", ["assessment_group_id"], :name => "index_assessment_group_batches_on_assessment_group_id", :limit => {"assessment_group_id"=>nil}
  add_index "assessment_group_batches", ["batch_id"], :name => "index_assessment_group_batches_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "assessment_group_batches", ["course_id"], :name => "index_assessment_group_batches_on_course_id", :limit => {"course_id"=>nil}
  add_index "assessment_group_batches", ["marks_added"], :name => "index_assessment_group_batches_on_marks_added", :limit => {"marks_added"=>nil}
  add_index "assessment_group_batches", ["school_id"], :name => "index_assessment_group_batches_on_school_id", :limit => {"school_id"=>nil}

  create_table "assessment_groups", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.string   "display_name"
    t.string   "type"
    t.integer  "parent_id"
    t.string   "parent_type"
    t.integer  "assessment_plan_id"
    t.integer  "assessment_activity_profile_id"
    t.integer  "scoring_type"
    t.integer  "grade_set_id"
    t.boolean  "is_single_mark_entry",                                           :default => true
    t.boolean  "is_attribute_same",                                              :default => true
    t.integer  "assessment_attribute_profile_id"
    t.decimal  "maximum_marks",                   :precision => 10, :scale => 2
    t.decimal  "minimum_marks",                   :precision => 10, :scale => 2
    t.integer  "academic_year_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_final_term",                                                  :default => false
    t.boolean  "no_exam",                                                        :default => false
    t.boolean  "consider_attendance",                                            :default => false
    t.boolean  "consider_skills",                                                :default => false
    t.boolean  "hide_marks",                                                     :default => false
    t.integer  "school_id"
  end

  add_index "assessment_groups", ["academic_year_id"], :name => "index_assessment_groups_on_academic_year_id", :limit => {"academic_year_id"=>nil}
  add_index "assessment_groups", ["assessment_activity_profile_id"], :name => "index_assessment_groups_on_assessment_activity_profile_id", :limit => {"assessment_activity_profile_id"=>nil}
  add_index "assessment_groups", ["assessment_attribute_profile_id"], :name => "index_assessment_groups_on_assessment_attribute_profile_id", :limit => {"assessment_attribute_profile_id"=>nil}
  add_index "assessment_groups", ["assessment_plan_id"], :name => "index_assessment_groups_on_assessment_plan_id", :limit => {"assessment_plan_id"=>nil}
  add_index "assessment_groups", ["grade_set_id"], :name => "index_assessment_groups_on_grade_set_id", :limit => {"grade_set_id"=>nil}
  add_index "assessment_groups", ["is_final_term"], :name => "index_assessment_groups_on_is_final_term", :limit => {"is_final_term"=>nil}
  add_index "assessment_groups", ["parent_id", "parent_type"], :name => "index_assessment_groups_on_parent_id_and_parent_type", :limit => {"parent_type"=>nil, "parent_id"=>nil}
  add_index "assessment_groups", ["school_id"], :name => "index_assessment_groups_on_school_id", :limit => {"school_id"=>nil}
  add_index "assessment_groups", ["type"], :name => "index_assessment_groups_on_type", :limit => {"type"=>nil}

  create_table "assessment_marks", :force => true do |t|
    t.integer  "student_id"
    t.string   "assessment_type"
    t.integer  "assessment_id"
    t.decimal  "marks",           :precision => 10, :scale => 2
    t.string   "grade"
    t.integer  "grade_id"
    t.boolean  "is_absent",                                      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "assessment_marks", ["assessment_id", "assessment_type"], :name => "index_assessment_marks_on_assessment_id_and_assessment_type", :limit => {"assessment_id"=>nil, "assessment_type"=>nil}
  add_index "assessment_marks", ["grade_id"], :name => "index_assessment_marks_on_grade_id", :limit => {"grade_id"=>nil}
  add_index "assessment_marks", ["school_id"], :name => "index_assessment_marks_on_school_id", :limit => {"school_id"=>nil}
  add_index "assessment_marks", ["student_id"], :name => "index_assessment_marks_on_student_id", :limit => {"student_id"=>nil}

  create_table "assessment_plan_imports", :force => true do |t|
    t.integer  "import_from"
    t.integer  "import_to"
    t.text     "assessment_plan_ids"
    t.text     "import_settings"
    t.integer  "status"
    t.text     "last_error"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "assessment_plan_imports", ["school_id"], :name => "index_assessment_plan_imports_on_school_id", :limit => {"school_id"=>nil}

  create_table "assessment_plans", :force => true do |t|
    t.string   "name"
    t.integer  "terms_count"
    t.integer  "academic_year_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "previous_id"
    t.string   "report_template_name"
    t.integer  "school_id"
  end

  add_index "assessment_plans", ["academic_year_id"], :name => "index_assessment_plans_on_academic_year_id", :limit => {"academic_year_id"=>nil}
  add_index "assessment_plans", ["school_id"], :name => "index_assessment_plans_on_school_id", :limit => {"school_id"=>nil}

  create_table "assessment_plans_courses", :force => true do |t|
    t.integer  "assessment_plan_id"
    t.integer  "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "assessment_plans_courses", ["assessment_plan_id"], :name => "index_assessment_plans_courses_on_assessment_plan_id", :limit => {"assessment_plan_id"=>nil}
  add_index "assessment_plans_courses", ["course_id"], :name => "index_assessment_plans_courses_on_course_id", :limit => {"course_id"=>nil}
  add_index "assessment_plans_courses", ["school_id"], :name => "index_assessment_plans_courses_on_school_id", :limit => {"school_id"=>nil}

  create_table "assessment_report_setting_copies", :force => true do |t|
    t.integer  "generated_report_id"
    t.text     "settings"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "assessment_report_setting_copies", ["school_id"], :name => "index_assessment_report_setting_copies_on_school_id", :limit => {"school_id"=>nil}

  create_table "assessment_report_settings", :force => true do |t|
    t.integer  "assessment_plan_id"
    t.string   "setting_key"
    t.string   "setting_value"
    t.string   "signature_file_name"
    t.string   "signature_content_type"
    t.string   "signature_file_size"
    t.datetime "signature_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "assessment_report_settings", ["assessment_plan_id"], :name => "index_assessment_report_settings_on_assessment_plan_id", :limit => {"assessment_plan_id"=>nil}
  add_index "assessment_report_settings", ["school_id"], :name => "index_assessment_report_settings_on_school_id", :limit => {"school_id"=>nil}

  create_table "assessment_schedules", :force => true do |t|
    t.integer  "assessment_group_id"
    t.integer  "course_id"
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "no_of_exams_per_day",  :default => 1
    t.text     "exam_timings"
    t.boolean  "schedule_created",     :default => false
    t.boolean  "schedule_published",   :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "mark_entry_last_date"
    t.integer  "school_id"
  end

  add_index "assessment_schedules", ["assessment_group_id"], :name => "index_assessment_schedules_on_assessment_group_id", :limit => {"assessment_group_id"=>nil}
  add_index "assessment_schedules", ["course_id"], :name => "index_assessment_schedules_on_course_id", :limit => {"course_id"=>nil}
  add_index "assessment_schedules", ["schedule_created"], :name => "index_assessment_schedules_on_schedule_created", :limit => {"schedule_created"=>nil}
  add_index "assessment_schedules", ["school_id"], :name => "index_assessment_schedules_on_school_id", :limit => {"school_id"=>nil}

  create_table "assessment_schedules_batches", :id => false, :force => true do |t|
    t.integer "assessment_schedule_id"
    t.integer "batch_id"
  end

  add_index "assessment_schedules_batches", ["assessment_schedule_id"], :name => "index_assessment_schedules_batches_on_assessment_schedule_id", :limit => {"assessment_schedule_id"=>nil}
  add_index "assessment_schedules_batches", ["batch_id"], :name => "index_assessment_schedules_batches_on_batch_id", :limit => {"batch_id"=>nil}

  create_table "assessment_score_imports", :force => true do |t|
    t.integer  "assessment_group_id"
    t.string   "batch_id"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.string   "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.integer  "status"
    t.text     "last_message",            :limit => 2147483647
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "assessment_score_imports", ["school_id"], :name => "index_assessment_score_imports_on_school_id", :limit => {"school_id"=>nil}

  create_table "assessment_scores", :force => true do |t|
    t.integer  "student_id"
    t.float    "grade_points"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "exam_id"
    t.integer  "batch_id"
    t.integer  "descriptive_indicator_id"
    t.integer  "subject_id",               :default => 0, :null => false
    t.integer  "cce_exam_category_id"
    t.integer  "school_id"
  end

  add_index "assessment_scores", ["batch_id", "descriptive_indicator_id", "subject_id", "student_id"], :name => "batch_di_subject_student_unique_index", :unique => true, :limit => {"student_id"=>nil, "batch_id"=>nil, "descriptive_indicator_id"=>nil, "subject_id"=>nil}
  add_index "assessment_scores", ["cce_exam_category_id"], :name => "index_assessment_scores_on_cce_exam_category_id", :limit => {"cce_exam_category_id"=>nil}
  add_index "assessment_scores", ["descriptive_indicator_id"], :name => "index_assessment_scores_on_descriptive_indicator_id", :limit => {"descriptive_indicator_id"=>nil}
  add_index "assessment_scores", ["exam_id"], :name => "index_assessment_scores_on_exam_id", :limit => {"exam_id"=>nil}
  add_index "assessment_scores", ["school_id"], :name => "index_assessment_scores_on_school_id", :limit => {"school_id"=>nil}
  add_index "assessment_scores", ["student_id", "batch_id", "descriptive_indicator_id", "exam_id"], :name => "score_index", :limit => {"batch_id"=>nil, "student_id"=>nil, "descriptive_indicator_id"=>nil, "exam_id"=>nil}
  add_index "assessment_scores", ["subject_id"], :name => "index_assessment_scores_on_subject_id", :limit => {"subject_id"=>nil}

  create_table "assessment_terms", :force => true do |t|
    t.string   "name"
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "assessment_plan_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "assessment_terms", ["assessment_plan_id"], :name => "index_assessment_terms_on_assessment_plan_id", :limit => {"assessment_plan_id"=>nil}
  add_index "assessment_terms", ["school_id"], :name => "index_assessment_terms_on_school_id", :limit => {"school_id"=>nil}

  create_table "asset_entries", :force => true do |t|
    t.text     "dynamic_attributes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_asset_id"
    t.integer  "school_id"
  end

  add_index "asset_entries", ["school_id"], :name => "index_asset_entries_on_school_id", :limit => {"school_id"=>nil}

  create_table "asset_field_options", :force => true do |t|
    t.integer  "asset_field_id"
    t.string   "option"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "asset_field_options", ["school_id"], :name => "index_asset_field_options_on_school_id", :limit => {"school_id"=>nil}

  create_table "asset_fields", :force => true do |t|
    t.integer  "school_asset_id"
    t.string   "field_name"
    t.string   "field_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "asset_fields", ["school_id"], :name => "index_asset_fields_on_school_id", :limit => {"school_id"=>nil}

  create_table "assets", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.decimal  "amount",      :precision => 15, :scale => 4
    t.boolean  "is_inactive",                                :default => false
    t.boolean  "is_deleted",                                 :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "assets", ["school_id"], :name => "index_assets_on_school_id", :limit => {"school_id"=>nil}

  create_table "assignable_folders_folder_assignment_types", :id => false, :force => true do |t|
    t.integer "assignable_folder_id"
    t.integer "folder_assignment_type_id"
  end

  create_table "assigned_packages", :force => true do |t|
    t.integer  "sms_package_id"
    t.integer  "assignee_id"
    t.string   "assignee_type"
    t.boolean  "is_using",                       :default => false
    t.boolean  "enable_sendername_modification", :default => false
    t.string   "sendername"
    t.integer  "sms_count"
    t.date     "validity"
    t.integer  "sms_used"
    t.boolean  "is_owner",                       :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "assigned_packages", ["assignee_id", "assignee_type"], :name => "index_assigned_packages_on_assignee_id_and_assignee_type", :limit => {"assignee_type"=>nil, "assignee_id"=>nil}
  add_index "assigned_packages", ["sms_package_id"], :name => "index_assigned_packages_on_sms_package_id", :limit => {"sms_package_id"=>nil}

  create_table "assignment_answers", :force => true do |t|
    t.integer  "assignment_id"
    t.integer  "student_id"
    t.string   "status",                  :default => "0"
    t.string   "title"
    t.text     "content"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "assignment_answers", ["school_id"], :name => "index_assignment_answers_on_school_id", :limit => {"school_id"=>nil}

  create_table "assignments", :force => true do |t|
    t.integer  "employee_id"
    t.integer  "subject_id"
    t.text     "student_list"
    t.string   "title"
    t.text     "content"
    t.datetime "duedate"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "assignments", ["school_id"], :name => "index_assignments_on_school_id", :limit => {"school_id"=>nil}

  create_table "attendance_labels", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.string   "attendance_type"
    t.float    "weightage"
    t.boolean  "is_active"
    t.boolean  "has_notification"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_default"
    t.integer  "school_id"
  end

  add_index "attendance_labels", ["attendance_type"], :name => "index_by_attendance_type", :limit => {"attendance_type"=>nil}
  add_index "attendance_labels", ["school_id"], :name => "index_attendance_labels_on_school_id", :limit => {"school_id"=>nil}

  create_table "attendance_settings", :force => true do |t|
    t.string   "setting_key"
    t.boolean  "is_enable"
    t.string   "user_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "attendance_settings", ["school_id"], :name => "index_attendance_settings_on_school_id", :limit => {"school_id"=>nil}

  create_table "attendance_weekday_sets", :force => true do |t|
    t.integer  "batch_id"
    t.integer  "weekday_set_id"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "attendance_weekday_sets", ["school_id"], :name => "index_attendance_weekday_sets_on_school_id", :limit => {"school_id"=>nil}

  create_table "attendances", :force => true do |t|
    t.integer  "student_id"
    t.integer  "period_table_entry_id"
    t.boolean  "forenoon",              :default => false
    t.boolean  "afternoon",             :default => false
    t.string   "reason"
    t.date     "month_date"
    t.integer  "batch_id"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.boolean  "notification_sent"
    t.integer  "attendance_label_id"
    t.float    "weightage"
    t.integer  "school_id"
  end

  add_index "attendances", ["attendance_label_id"], :name => "index_by_attendance_label_id", :limit => {"attendance_label_id"=>nil}
  add_index "attendances", ["month_date", "batch_id"], :name => "index_attendances_on_month_date_and_batch_id", :limit => {"month_date"=>nil, "batch_id"=>nil}
  add_index "attendances", ["school_id"], :name => "index_attendances_on_school_id", :limit => {"school_id"=>nil}
  add_index "attendances", ["student_id", "batch_id"], :name => "index_attendances_on_student_id_and_batch_id", :limit => {"batch_id"=>nil, "student_id"=>nil}

  create_table "attribute_assessments", :force => true do |t|
    t.integer  "assessment_group_batch_id"
    t.integer  "subject_id"
    t.integer  "assessment_attribute_profile_id"
    t.integer  "assessment_attribute_id"
    t.boolean  "marks_added",                     :default => false
    t.integer  "submission_status"
    t.boolean  "edited",                          :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "subject_attribute_assessment_id"
    t.integer  "school_id"
  end

  add_index "attribute_assessments", ["assessment_attribute_id"], :name => "index_attribute_assessments_on_assessment_attribute_id", :limit => {"assessment_attribute_id"=>nil}
  add_index "attribute_assessments", ["assessment_attribute_profile_id"], :name => "index_attribute_assessments_on_assessment_attribute_profile_id", :limit => {"assessment_attribute_profile_id"=>nil}
  add_index "attribute_assessments", ["assessment_group_batch_id"], :name => "index_attribute_assessments_on_assessment_group_batch_id", :limit => {"assessment_group_batch_id"=>nil}
  add_index "attribute_assessments", ["marks_added"], :name => "index_attribute_assessments_on_marks_added", :limit => {"marks_added"=>nil}
  add_index "attribute_assessments", ["school_id"], :name => "index_attribute_assessments_on_school_id", :limit => {"school_id"=>nil}
  add_index "attribute_assessments", ["subject_id"], :name => "index_attribute_assessments_on_subject_id", :limit => {"subject_id"=>nil}

  create_table "available_plugins", :force => true do |t|
    t.integer  "associated_id"
    t.string   "associated_type"
    t.text     "plugins"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "available_plugins", ["associated_id", "associated_type"], :name => "index_available_plugins_on_associated_id_and_associated_type", :limit => {"associated_type"=>nil, "associated_id"=>nil}

  create_table "bank_fields", :force => true do |t|
    t.string   "name"
    t.boolean  "status"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "bank_fields", ["school_id"], :name => "index_bank_fields_on_school_id", :limit => {"school_id"=>nil}

  create_table "barcode_properties", :force => true do |t|
    t.string   "linked_to"
    t.integer  "rotate"
    t.integer  "base_template_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "barcode_properties", ["school_id"], :name => "index_barcode_properties_on_school_id", :limit => {"school_id"=>nil}

  create_table "base_templates", :force => true do |t|
    t.integer  "template_for"
    t.text     "template_data"
    t.string   "profile_photo_type"
    t.integer  "profile_photo_dimension"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "base_templates", ["school_id"], :name => "index_base_templates_on_school_id", :limit => {"school_id"=>nil}

  create_table "batch_class_timing_sets", :force => true do |t|
    t.integer  "batch_id"
    t.integer  "class_timing_set_id"
    t.integer  "weekday_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "batch_class_timing_sets", ["batch_id", "class_timing_set_id", "weekday_id"], :name => "bctw_index", :limit => {"batch_id"=>nil, "weekday_id"=>nil, "class_timing_set_id"=>nil}
  add_index "batch_class_timing_sets", ["batch_id"], :name => "index_batch_class_timing_sets_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "batch_class_timing_sets", ["class_timing_set_id"], :name => "index_batch_class_timing_sets_on_class_timing_set_id", :limit => {"class_timing_set_id"=>nil}
  add_index "batch_class_timing_sets", ["school_id"], :name => "index_batch_class_timing_sets_on_school_id", :limit => {"school_id"=>nil}

  create_table "batch_events", :force => true do |t|
    t.integer  "event_id"
    t.integer  "batch_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "batch_events", ["batch_id"], :name => "index_batch_events_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "batch_events", ["school_id"], :name => "index_batch_events_on_school_id", :limit => {"school_id"=>nil}

  create_table "batch_groups", :force => true do |t|
    t.integer  "course_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "batch_groups", ["school_id"], :name => "index_batch_groups_on_school_id", :limit => {"school_id"=>nil}

  create_table "batch_students", :force => true do |t|
    t.integer  "student_id"
    t.integer  "batch_id"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "roll_number"
    t.integer  "school_id"
  end

  add_index "batch_students", ["batch_id", "student_id"], :name => "index_batch_students_on_batch_id_and_student_id", :limit => {"student_id"=>nil, "batch_id"=>nil}
  add_index "batch_students", ["school_id"], :name => "index_batch_students_on_school_id", :limit => {"school_id"=>nil}
  add_index "batch_students", ["student_id"], :name => "index_batch_students_on_student_id", :limit => {"student_id"=>nil}

  create_table "batch_subject_groups", :force => true do |t|
    t.integer  "subject_group_id"
    t.integer  "batch_id"
    t.string   "name"
    t.integer  "priority"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_deleted",       :default => false
    t.boolean  "calculate_final",  :default => false
    t.string   "formula"
    t.integer  "school_id"
  end

  add_index "batch_subject_groups", ["school_id"], :name => "index_batch_subject_groups_on_school_id", :limit => {"school_id"=>nil}

  create_table "batch_timetable_summaries", :force => true do |t|
    t.integer  "batch_id"
    t.text     "timetable_summary"
    t.integer  "timetable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "batch_tutors", :id => false, :force => true do |t|
    t.integer "employee_id"
    t.integer "batch_id"
  end

  add_index "batch_tutors", ["employee_id", "batch_id"], :name => "index_batch_tutors_on_employee_id_and_batch_id", :limit => {"employee_id"=>nil, "batch_id"=>nil}

  create_table "batch_wise_student_reports", :force => true do |t|
    t.string   "status"
    t.text     "parameters"
    t.string   "report_file_name"
    t.string   "report_content_type"
    t.integer  "report_file_size"
    t.datetime "report_updated_at"
    t.integer  "course_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_gradebook",        :default => false
  end

  add_index "batch_wise_student_reports", ["is_gradebook"], :name => "index_batch_wise_student_reports_on_is_gradebook", :limit => {"is_gradebook"=>nil}

  create_table "batches", :force => true do |t|
    t.string   "name"
    t.integer  "course_id"
    t.datetime "start_date"
    t.datetime "end_date"
    t.boolean  "is_active",           :default => true
    t.boolean  "is_deleted",          :default => false
    t.string   "employee_id"
    t.integer  "weekday_set_id"
    t.integer  "class_timing_set_id"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "roll_number_prefix"
    t.integer  "academic_year_id"
    t.integer  "school_id"
  end

  add_index "batches", ["academic_year_id"], :name => "index_batches_on_academic_year_id", :limit => {"academic_year_id"=>nil}
  add_index "batches", ["course_id"], :name => "index_batches_on_course_id", :limit => {"course_id"=>nil}
  add_index "batches", ["is_active"], :name => "index_batches_on_is_active", :limit => {"is_active"=>nil}
  add_index "batches", ["is_deleted", "is_active", "course_id", "name"], :name => "index_batches_on_is_deleted_and_is_active_and_course_id_and_name", :limit => {"name"=>nil, "course_id"=>nil, "is_deleted"=>nil, "is_active"=>nil}
  add_index "batches", ["is_deleted"], :name => "index_batches_on_is_deleted", :limit => {"is_deleted"=>nil}
  add_index "batches", ["school_id"], :name => "index_batches_on_school_id", :limit => {"school_id"=>nil}

  create_table "biometric_informations", :force => true do |t|
    t.integer  "user_id"
    t.string   "biometric_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "biometric_informations", ["school_id"], :name => "index_biometric_informations_on_school_id", :limit => {"school_id"=>nil}
  add_index "biometric_informations", ["user_id"], :name => "index_on_user_id", :limit => {"user_id"=>nil}

  create_table "book_additional_details", :force => true do |t|
    t.integer  "book_id"
    t.integer  "book_additional_field_id"
    t.string   "additional_info"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "book_additional_details", ["school_id"], :name => "index_book_additional_details_on_school_id", :limit => {"school_id"=>nil}

  create_table "book_additional_field_options", :force => true do |t|
    t.string   "field_option"
    t.integer  "book_additional_field_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "book_additional_field_options", ["school_id"], :name => "index_book_additional_field_options_on_school_id", :limit => {"school_id"=>nil}

  create_table "book_additional_fields", :force => true do |t|
    t.string   "name"
    t.boolean  "is_mandatory"
    t.string   "input_type"
    t.integer  "priority"
    t.boolean  "is_active"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "book_additional_fields", ["school_id"], :name => "index_book_additional_fields_on_school_id", :limit => {"school_id"=>nil}

  create_table "book_movements", :force => true do |t|
    t.integer  "user_id"
    t.integer  "book_id"
    t.date     "issue_date"
    t.date     "due_date"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.integer  "financial_year_id"
  end

  add_index "book_movements", ["financial_year_id"], :name => "index_by_fyid", :limit => {"financial_year_id"=>nil}
  add_index "book_movements", ["school_id"], :name => "index_book_movements_on_school_id", :limit => {"school_id"=>nil}

  create_table "book_reservations", :force => true do |t|
    t.integer  "user_id"
    t.integer  "book_id"
    t.datetime "reserved_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "book_reservations", ["school_id"], :name => "index_book_reservations_on_school_id", :limit => {"school_id"=>nil}

  create_table "books", :force => true do |t|
    t.string   "title"
    t.string   "author"
    t.string   "book_number"
    t.integer  "book_movement_id"
    t.string   "status",           :default => "Available"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.string   "barcode"
  end

  add_index "books", ["barcode"], :name => "index_books_on_barcode", :limit => {"barcode"=>nil}
  add_index "books", ["book_number"], :name => "index_books_on_book_number", :limit => {"book_number"=>nil}
  add_index "books", ["school_id"], :name => "index_books_on_school_id", :limit => {"school_id"=>nil}

  create_table "buildings", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_deleted"
    t.integer  "school_id"
  end

  add_index "buildings", ["school_id"], :name => "index_buildings_on_school_id", :limit => {"school_id"=>nil}

  create_table "bulk_generated_certificates", :force => true do |t|
    t.integer  "certificate_template_id"
    t.integer  "academic_year_id"
    t.date     "issued_on"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bulk_generated_certificates", ["school_id"], :name => "index_bulk_generated_certificates_on_school_id", :limit => {"school_id"=>nil}

  create_table "bulk_generated_id_cards", :force => true do |t|
    t.text     "pdf_content"
    t.integer  "id_card_template_id"
    t.integer  "academic_year_id"
    t.date     "issued_on"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bulk_generated_id_cards", ["school_id"], :name => "index_bulk_generated_id_cards_on_school_id", :limit => {"school_id"=>nil}

  create_table "cancelled_advance_fee_transactions", :force => true do |t|
    t.decimal  "fees_paid",                                   :precision => 15, :scale => 2
    t.string   "payment_mode"
    t.date     "date_of_advance_fee_payment"
    t.string   "reference_no"
    t.string   "payment_note"
    t.string   "bank_name"
    t.date     "cheque_date"
    t.string   "reason_for_cancel"
    t.string   "transaction_data",            :limit => 1221
    t.integer  "user_id"
    t.integer  "advance_fee_category_id"
    t.integer  "student_id"
    t.integer  "advance_fee_collection_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "transaction_receipt_id"
    t.integer  "batch_id"
    t.integer  "school_id"
  end

  add_index "cancelled_advance_fee_transactions", ["school_id"], :name => "index_cancelled_advance_fee_transactions_on_school_id", :limit => {"school_id"=>nil}

  create_table "cancelled_finance_transactions", :force => true do |t|
    t.string   "title"
    t.string   "description"
    t.decimal  "amount",                              :precision => 15, :scale => 4
    t.boolean  "fine_included",                                                      :default => false
    t.integer  "category_id"
    t.integer  "student_id"
    t.integer  "finance_fees_id"
    t.date     "transaction_date"
    t.decimal  "fine_amount",                         :precision => 10, :scale => 4, :default => 0.0
    t.integer  "master_transaction_id",                                              :default => 0
    t.integer  "finance_id"
    t.string   "finance_type"
    t.integer  "payee_id"
    t.string   "payee_type"
    t.string   "receipt_no"
    t.string   "voucher_no"
    t.integer  "lastvchid"
    t.string   "payment_mode"
    t.text     "payment_note"
    t.integer  "user_id"
    t.string   "collection_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "batch_id"
    t.decimal  "auto_fine",                           :precision => 15, :scale => 4
    t.text     "other_details"
    t.integer  "finance_transaction_id"
    t.string   "reference_no"
    t.string   "trans_type"
    t.integer  "transaction_stamp",      :limit => 8
    t.text     "cancel_reason"
    t.integer  "transaction_ledger_id"
    t.decimal  "tax_amount",                          :precision => 15, :scale => 4, :default => 0.0
    t.boolean  "tax_included",                                                       :default => false
    t.string   "bank_name"
    t.string   "cheque_date"
    t.integer  "school_id"
    t.integer  "financial_year_id"
    t.boolean  "wallet_amount_applied",                                              :default => false
    t.decimal  "wallet_amount",                       :precision => 15, :scale => 2, :default => 0.0
  end

  add_index "cancelled_finance_transactions", ["finance_transaction_id", "transaction_stamp"], :name => "index_on_finance_transaction_id_and_transaction_stamp", :limit => {"finance_transaction_id"=>nil, "transaction_stamp"=>nil}
  add_index "cancelled_finance_transactions", ["school_id", "finance_transaction_id"], :name => "index_by_school_id_and_ft_id", :limit => {"finance_transaction_id"=>nil, "school_id"=>nil}
  add_index "cancelled_finance_transactions", ["school_id"], :name => "index_cancelled_finance_transactions_on_school_id", :limit => {"school_id"=>nil}
  add_index "cancelled_finance_transactions", ["transaction_ledger_id"], :name => "index_by_transaction_leger_id", :limit => {"transaction_ledger_id"=>nil}

  create_table "category_batches", :force => true do |t|
    t.integer  "finance_fee_category_id"
    t.integer  "batch_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "category_batches", ["finance_fee_category_id", "batch_id"], :name => "index_category_batches_on_finance_fee_category_id_and_batch_id", :limit => {"batch_id"=>nil, "finance_fee_category_id"=>nil}
  add_index "category_batches", ["school_id"], :name => "index_category_batches_on_school_id", :limit => {"school_id"=>nil}

  create_table "cbse_co_scholastic_settings", :force => true do |t|
    t.integer  "course_id"
    t.integer  "observation_id"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "cbse_co_scholastic_settings", ["school_id"], :name => "index_cbse_co_scholastic_settings_on_school_id", :limit => {"school_id"=>nil}

  create_table "cce_exam_categories", :force => true do |t|
    t.string   "name"
    t.string   "desc"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "cce_exam_categories", ["school_id"], :name => "index_cce_exam_categories_on_school_id", :limit => {"school_id"=>nil}

  create_table "cce_grade_sets", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "cce_grade_sets", ["school_id"], :name => "index_cce_grade_sets_on_school_id", :limit => {"school_id"=>nil}

  create_table "cce_grades", :force => true do |t|
    t.string   "name"
    t.float    "grade_point"
    t.integer  "cce_grade_set_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "cce_grades", ["cce_grade_set_id"], :name => "index_cce_grades_on_cce_grade_set_id", :limit => {"cce_grade_set_id"=>nil}
  add_index "cce_grades", ["school_id"], :name => "index_cce_grades_on_school_id", :limit => {"school_id"=>nil}

  create_table "cce_report_setting_copies", :force => true do |t|
    t.integer  "student_id"
    t.integer  "batch_id"
    t.string   "setting_key"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "cce_report_setting_copies", ["school_id"], :name => "index_cce_report_setting_copies_on_school_id", :limit => {"school_id"=>nil}

  create_table "cce_report_settings", :force => true do |t|
    t.string   "setting_key"
    t.string   "setting_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "cce_report_settings", ["school_id"], :name => "index_cce_report_settings_on_school_id", :limit => {"school_id"=>nil}

  create_table "cce_reports", :force => true do |t|
    t.integer  "observable_id"
    t.string   "observable_type"
    t.integer  "student_id"
    t.integer  "batch_id"
    t.string   "grade_string"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "exam_id"
    t.float    "max_mark"
    t.float    "obtained_mark"
    t.float    "converted_mark"
    t.integer  "subject_id"
    t.integer  "cce_exam_category_id"
    t.integer  "school_id"
  end

  add_index "cce_reports", ["grade_string"], :name => "index_cce_reports_on_grade_string", :limit => {"grade_string"=>nil}
  add_index "cce_reports", ["observable_id", "student_id", "batch_id", "exam_id", "observable_type"], :name => "cce_report_join_index", :limit => {"batch_id"=>nil, "student_id"=>nil, "observable_id"=>nil, "observable_type"=>nil, "exam_id"=>nil}
  add_index "cce_reports", ["observable_id"], :name => "index_cce_reports_on_observable_id", :limit => {"observable_id"=>nil}
  add_index "cce_reports", ["observable_type"], :name => "index_cce_reports_on_observable_type", :limit => {"observable_type"=>nil}
  add_index "cce_reports", ["school_id"], :name => "index_cce_reports_on_school_id", :limit => {"school_id"=>nil}
  add_index "cce_reports", ["student_id"], :name => "index_cce_reports_on_student_id", :limit => {"student_id"=>nil}

  create_table "cce_weightages", :force => true do |t|
    t.integer  "weightage"
    t.string   "criteria_type"
    t.integer  "cce_exam_category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "cce_weightages", ["school_id"], :name => "index_cce_weightages_on_school_id", :limit => {"school_id"=>nil}

  create_table "cce_weightages_courses", :id => false, :force => true do |t|
    t.integer "cce_weightage_id"
    t.integer "course_id"
  end

  add_index "cce_weightages_courses", ["cce_weightage_id"], :name => "index_cce_weightages_courses_on_cce_weightage_id", :limit => {"cce_weightage_id"=>nil}
  add_index "cce_weightages_courses", ["course_id", "cce_weightage_id"], :name => "index_for_join_table_cce_weightage_courses", :limit => {"course_id"=>nil, "cce_weightage_id"=>nil}
  add_index "cce_weightages_courses", ["course_id"], :name => "index_cce_weightages_courses_on_course_id", :limit => {"course_id"=>nil}

  create_table "certificate_templates", :force => true do |t|
    t.string   "name"
    t.integer  "user_type"
    t.boolean  "manual_serial_no"
    t.string   "serial_no_prefix"
    t.integer  "base_template_id"
    t.integer  "top_padding"
    t.integer  "right_padding"
    t.integer  "left_padding"
    t.integer  "bottom_padding"
    t.boolean  "include_header"
    t.string   "background_image_file_name"
    t.string   "background_image_content_type"
    t.integer  "background_image_file_size"
    t.datetime "background_image_updated_at"
    t.integer  "template_resolutions_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "certificate_templates", ["school_id"], :name => "index_certificate_templates_on_school_id", :limit => {"school_id"=>nil}

  create_table "certificate_types", :force => true do |t|
    t.string   "name"
    t.boolean  "send_reminders", :default => true
    t.boolean  "is_active",      :default => true
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "certificate_types", ["is_active"], :name => "index_certificate_types_on_is_active", :limit => {"is_active"=>nil}
  add_index "certificate_types", ["school_id"], :name => "index_certificate_types_on_school_id", :limit => {"school_id"=>nil}
  add_index "certificate_types", ["send_reminders"], :name => "index_certificate_types_on_send_reminders", :limit => {"send_reminders"=>nil}

  create_table "class_designations", :force => true do |t|
    t.string   "name",                                      :null => false
    t.decimal  "cgpa",       :precision => 15, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "marks",      :precision => 15, :scale => 2
    t.integer  "course_id"
    t.integer  "school_id"
  end

  add_index "class_designations", ["school_id"], :name => "index_class_designations_on_school_id", :limit => {"school_id"=>nil}

  create_table "class_timing_sets", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "class_timing_sets", ["school_id"], :name => "index_class_timing_sets_on_school_id", :limit => {"school_id"=>nil}

  create_table "class_timing_sets_class_timings", :force => true do |t|
    t.integer  "class_timing_set_id"
    t.integer  "class_timing_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "class_timings", :force => true do |t|
    t.integer  "batch_id"
    t.string   "name"
    t.time     "start_time"
    t.time     "end_time"
    t.boolean  "is_break"
    t.boolean  "is_deleted",          :default => false
    t.integer  "class_timing_set_id"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "class_timings", ["batch_id", "start_time", "end_time"], :name => "index_class_timings_on_batch_id_and_start_time_and_end_time", :limit => {"start_time"=>nil, "batch_id"=>nil, "end_time"=>nil}
  add_index "class_timings", ["class_timing_set_id"], :name => "index_class_timings_on_class_timing_set_id", :limit => {"class_timing_set_id"=>nil}
  add_index "class_timings", ["school_id"], :name => "index_class_timings_on_school_id", :limit => {"school_id"=>nil}

  create_table "classroom_allocations", :force => true do |t|
    t.string   "allocation_type"
    t.integer  "timetable_id"
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "classroom_allocations", ["school_id"], :name => "index_classroom_allocations_on_school_id", :limit => {"school_id"=>nil}
  add_index "classroom_allocations", ["timetable_id"], :name => "index_classroom_allocations_on_timetable_id", :limit => {"timetable_id"=>nil}

  create_table "classrooms", :force => true do |t|
    t.string   "name"
    t.integer  "building_id"
    t.integer  "capacity"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_deleted"
    t.integer  "school_id"
  end

  add_index "classrooms", ["building_id"], :name => "index_classrooms_on_building_id", :limit => {"building_id"=>nil}
  add_index "classrooms", ["school_id"], :name => "index_classrooms_on_school_id", :limit => {"school_id"=>nil}

  create_table "collectible_tax_slabs", :force => true do |t|
    t.integer  "collectible_entity_id",   :null => false
    t.string   "collectible_entity_type", :null => false
    t.integer  "collection_id",           :null => false
    t.string   "collection_type",         :null => false
    t.integer  "tax_slab_id",             :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "collectible_tax_slabs", ["collectible_entity_type", "collectible_entity_id"], :name => "index_by_collectible_entity", :limit => {"collectible_entity_id"=>nil, "collectible_entity_type"=>nil}
  add_index "collectible_tax_slabs", ["collection_type", "collection_id"], :name => "index_by_collection", :limit => {"collection_type"=>nil, "collection_id"=>nil}
  add_index "collectible_tax_slabs", ["school_id"], :name => "index_collectible_tax_slabs_on_school_id", :limit => {"school_id"=>nil}
  add_index "collectible_tax_slabs", ["tax_slab_id"], :name => "index_by_tax_slab_id", :limit => {"tax_slab_id"=>nil}

  create_table "collection_discounts", :force => true do |t|
    t.integer  "finance_fee_collection_id"
    t.integer  "fee_discount_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "collection_discounts", ["finance_fee_collection_id", "fee_discount_id"], :name => "fee_discount_index", :limit => {"finance_fee_collection_id"=>nil, "fee_discount_id"=>nil}
  add_index "collection_discounts", ["school_id"], :name => "index_collection_discounts_on_school_id", :limit => {"school_id"=>nil}

  create_table "collection_master_particular_reports", :force => true do |t|
    t.integer  "financial_year_id"
    t.integer  "student_id",                                                               :null => false
    t.integer  "collection_id",                                                            :null => false
    t.string   "collection_type",                                                          :null => false
    t.integer  "master_fee_particular_id",                                                 :null => false
    t.decimal  "actual_amount",            :precision => 15, :scale => 4, :default => 0.0
    t.decimal  "discount_amount",          :precision => 15, :scale => 4, :default => 0.0
    t.decimal  "tax_amount",               :precision => 15, :scale => 4, :default => 0.0
    t.decimal  "amount",                   :precision => 15, :scale => 4, :default => 0.0
    t.string   "digest",                                                                   :null => false
    t.integer  "school_id",                                                                :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "batch_id",                                                                 :null => false
  end

  add_index "collection_master_particular_reports", ["digest", "student_id", "collection_id", "collection_type"], :name => "compound_index_on_digest_student_id_colllection", :unique => true, :limit => {"student_id"=>nil, "digest"=>nil, "collection_type"=>nil, "collection_id"=>nil}
  add_index "collection_master_particular_reports", ["school_id"], :name => "index_by_school_id", :limit => {"school_id"=>nil}

  create_table "collection_particulars", :force => true do |t|
    t.integer  "finance_fee_collection_id"
    t.integer  "finance_fee_particular_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "collection_particulars", ["finance_fee_collection_id", "finance_fee_particular_id"], :name => "fee_particular_index", :limit => {"finance_fee_collection_id"=>nil, "finance_fee_particular_id"=>nil}
  add_index "collection_particulars", ["school_id"], :name => "index_collection_particulars_on_school_id", :limit => {"school_id"=>nil}

  create_table "configurations", :force => true do |t|
    t.string   "config_key"
    t.string   "config_value"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "configurations", ["config_key"], :name => "index_configurations_on_config_key", :limit => {"config_key"=>"10"}
  add_index "configurations", ["config_value"], :name => "index_configurations_on_config_value", :limit => {"config_value"=>"10"}
  add_index "configurations", ["school_id"], :name => "index_configurations_on_school_id", :limit => {"school_id"=>nil}

  create_table "converted_assessment_marks", :force => true do |t|
    t.integer  "markable_id"
    t.string   "markable_type"
    t.integer  "assessment_group_batch_id"
    t.integer  "assessment_group_id"
    t.integer  "student_id"
    t.decimal  "mark",                      :precision => 10, :scale => 2
    t.string   "grade"
    t.decimal  "credit_points",             :precision => 10, :scale => 2
    t.boolean  "passed",                                                   :default => true
    t.string   "description"
    t.boolean  "is_absent",                                                :default => false
    t.text     "actual_mark"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "converted_assessment_marks", ["assessment_group_batch_id"], :name => "index_converted_assessment_marks_on_assessment_group_batch_id", :limit => {"assessment_group_batch_id"=>nil}
  add_index "converted_assessment_marks", ["assessment_group_id"], :name => "index_converted_assessment_marks_on_assessment_group_id", :limit => {"assessment_group_id"=>nil}
  add_index "converted_assessment_marks", ["markable_id", "markable_type"], :name => "index_on_different_assessments", :limit => {"markable_type"=>nil, "markable_id"=>nil}
  add_index "converted_assessment_marks", ["school_id"], :name => "index_converted_assessment_marks_on_school_id", :limit => {"school_id"=>nil}
  add_index "converted_assessment_marks", ["student_id"], :name => "index_converted_assessment_marks_on_student_id", :limit => {"student_id"=>nil}

  create_table "countries", :force => true do |t|
    t.string   "name"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "regional_name"
    t.string   "code"
    t.string   "currency_code"
  end

  create_table "course_elective_groups", :force => true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.string   "parent_type"
    t.boolean  "is_deleted",       :default => false
    t.date     "end_date"
    t.boolean  "is_sixth_subject", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "priority"
    t.integer  "course_id"
    t.integer  "import_from"
    t.integer  "previous_id"
    t.integer  "school_id"
  end

  add_index "course_elective_groups", ["course_id"], :name => "index_course_elective_groups_on_course_id", :limit => {"course_id"=>nil}
  add_index "course_elective_groups", ["priority"], :name => "index_course_elective_groups_on_priority", :limit => {"priority"=>nil}
  add_index "course_elective_groups", ["school_id"], :name => "index_course_elective_groups_on_school_id", :limit => {"school_id"=>nil}

  create_table "course_exam_groups", :force => true do |t|
    t.string   "name"
    t.integer  "course_id"
    t.string   "exam_type"
    t.integer  "cce_exam_category_id"
    t.integer  "icse_exam_category_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "course_pins", :force => true do |t|
    t.boolean  "is_pin_enabled"
    t.integer  "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  create_table "course_subjects", :force => true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.string   "parent_type"
    t.string   "code"
    t.boolean  "no_exams",                                               :default => false
    t.integer  "max_weekly_classes"
    t.boolean  "is_deleted",                                             :default => false
    t.decimal  "credit_hours",            :precision => 15, :scale => 2
    t.boolean  "prefer_consecutive",                                     :default => false
    t.decimal  "amount",                  :precision => 15, :scale => 2
    t.boolean  "is_asl",                                                 :default => false
    t.integer  "asl_mark"
    t.boolean  "is_sixth_subject"
    t.integer  "subject_skill_set_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id"
    t.integer  "priority"
    t.boolean  "is_activity",                                            :default => false
    t.integer  "import_from"
    t.integer  "previous_id"
    t.boolean  "exclude_for_final_score",                                :default => false
    t.integer  "school_id"
  end

  add_index "course_subjects", ["course_id"], :name => "index_course_subjects_on_course_id", :limit => {"course_id"=>nil}
  add_index "course_subjects", ["priority"], :name => "index_course_subjects_on_priority", :limit => {"priority"=>nil}
  add_index "course_subjects", ["school_id"], :name => "index_course_subjects_on_school_id", :limit => {"school_id"=>nil}

  create_table "course_transcript_settings", :force => true do |t|
    t.integer  "course_id"
    t.boolean  "show_grade"
    t.boolean  "show_percentage"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "course_transcript_settings", ["school_id"], :name => "index_course_transcript_settings_on_school_id", :limit => {"school_id"=>nil}

  create_table "courses", :force => true do |t|
    t.string   "course_name"
    t.string   "code"
    t.string   "section_name"
    t.boolean  "is_deleted",                        :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "grading_type"
    t.boolean  "enable_student_elective_selection", :default => false
    t.string   "roll_number_prefix"
    t.integer  "school_id"
  end

  add_index "courses", ["grading_type"], :name => "index_courses_on_grading_type", :limit => {"grading_type"=>nil}
  add_index "courses", ["is_deleted"], :name => "index_courses_on_is_deleted", :limit => {"is_deleted"=>nil}
  add_index "courses", ["school_id"], :name => "index_courses_on_school_id", :limit => {"school_id"=>nil}

  create_table "courses_observation_groups", :id => false, :force => true do |t|
    t.integer "course_id"
    t.integer "observation_group_id"
  end

  add_index "courses_observation_groups", ["course_id"], :name => "index_courses_observation_groups_on_course_id", :limit => {"course_id"=>nil}
  add_index "courses_observation_groups", ["observation_group_id"], :name => "index_courses_observation_groups_on_observation_group_id", :limit => {"observation_group_id"=>nil}

  create_table "custom_gateways", :force => true do |t|
    t.string   "name"
    t.text     "gateway_parameters"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_deleted",                :default => false
    t.text     "account_wise_parameters"
    t.boolean  "enable_account_wise_split", :default => false
  end

  create_table "custom_translations", :force => true do |t|
    t.string   "key"
    t.string   "translation"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "custom_translations", ["school_id"], :name => "index_custom_translations_on_school_id", :limit => {"school_id"=>nil}

  create_table "data_exports", :force => true do |t|
    t.integer  "export_structure_id"
    t.string   "file_format"
    t.string   "status"
    t.string   "export_file_file_name"
    t.string   "export_file_content_type"
    t.integer  "export_file_file_size"
    t.datetime "export_file_updated_at"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",                       :default => 0
    t.integer  "attempts",                       :default => 0
    t.text     "handler",    :limit => 16777215
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "queue"
  end

  add_index "delayed_jobs", ["locked_by"], :name => "index_delayed_jobs_on_locked_by", :limit => {"locked_by"=>nil}

  create_table "derived_assessment_group_settings", :force => true do |t|
    t.integer  "derived_assessment_group_id"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "derived_assessment_group_settings", ["derived_assessment_group_id"], :name => "index_on_derived_assessment_group_id", :limit => {"derived_assessment_group_id"=>nil}
  add_index "derived_assessment_group_settings", ["school_id"], :name => "index_derived_assessment_group_settings_on_school_id", :limit => {"school_id"=>nil}

  create_table "derived_assessment_groups_associations", :force => true do |t|
    t.integer  "derived_assessment_group_id"
    t.integer  "assessment_group_id"
    t.integer  "weightage",                   :limit => 10, :precision => 10, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "priority"
    t.integer  "school_id"
  end

  add_index "derived_assessment_groups_associations", ["assessment_group_id"], :name => "index_on_assessment_group_id", :limit => {"assessment_group_id"=>nil}
  add_index "derived_assessment_groups_associations", ["derived_assessment_group_id"], :name => "index_on_derived_assessment_group_id", :limit => {"derived_assessment_group_id"=>nil}
  add_index "derived_assessment_groups_associations", ["school_id"], :name => "index_derived_assessment_groups_associations_on_school_id", :limit => {"school_id"=>nil}

  create_table "descriptive_indicators", :force => true do |t|
    t.string   "name"
    t.string   "desc"
    t.integer  "describable_id"
    t.string   "describable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_order"
    t.boolean  "show_in_report",   :default => false
    t.integer  "school_id"
  end

  add_index "descriptive_indicators", ["describable_id", "describable_type", "sort_order"], :name => "describable_index", :limit => {"describable_type"=>nil, "describable_id"=>nil, "sort_order"=>nil}
  add_index "descriptive_indicators", ["school_id"], :name => "index_descriptive_indicators_on_school_id", :limit => {"school_id"=>nil}

  create_table "discipline_actions", :force => true do |t|
    t.text     "body"
    t.string   "remarks"
    t.integer  "school_id"
    t.integer  "user_id"
    t.integer  "discipline_complaint_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "discipline_actions", ["school_id"], :name => "index_discipline_actions_on_school_id", :limit => {"school_id"=>nil}
  add_index "discipline_actions", ["user_id"], :name => "index_discipline_actions_on_user_id", :limit => {"user_id"=>nil}

  create_table "discipline_attachments", :force => true do |t|
    t.integer  "school_id"
    t.integer  "discipline_participation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
  end

  create_table "discipline_comments", :force => true do |t|
    t.text     "body"
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.integer  "school_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "discipline_comments", ["school_id"], :name => "index_discipline_comments_on_school_id", :limit => {"school_id"=>nil}
  add_index "discipline_comments", ["user_id"], :name => "index_discipline_comments_on_user_id", :limit => {"user_id"=>nil}

  create_table "discipline_complaints", :force => true do |t|
    t.string   "subject"
    t.text     "body"
    t.date     "trial_date"
    t.integer  "school_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "complaint_no"
    t.boolean  "action_taken", :default => false
  end

  add_index "discipline_complaints", ["school_id"], :name => "index_discipline_complaints_on_school_id", :limit => {"school_id"=>nil}
  add_index "discipline_complaints", ["user_id"], :name => "index_discipline_complaints_on_user_id", :limit => {"user_id"=>nil}

  create_table "discipline_participations", :force => true do |t|
    t.string   "type"
    t.boolean  "action_taken"
    t.integer  "school_id"
    t.integer  "user_id"
    t.integer  "discipline_complaint_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "discipline_participations", ["school_id"], :name => "index_discipline_participations_on_school_id", :limit => {"school_id"=>nil}
  add_index "discipline_participations", ["user_id", "discipline_complaint_id", "type"], :name => "by_user_and_complaint", :limit => {"type"=>nil, "discipline_complaint_id"=>nil, "user_id"=>nil}

  create_table "discipline_student_actions", :force => true do |t|
    t.integer  "discipline_action_id"
    t.integer  "discipline_participation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "discipline_student_actions", ["discipline_participation_id", "discipline_action_id"], :name => "by_action_and_participation", :limit => {"discipline_participation_id"=>nil, "discipline_action_id"=>nil}

  create_table "discount_particular_logs", :force => true do |t|
    t.boolean  "is_amount"
    t.string   "receiver_type"
    t.integer  "finance_fee_id"
    t.integer  "user_id"
    t.string   "name"
    t.decimal  "amount",         :precision => 15, :scale => 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "discount_particular_logs", ["school_id"], :name => "index_discount_particular_logs_on_school_id", :limit => {"school_id"=>nil}

  create_table "discounts", :force => true do |t|
    t.string   "name"
    t.decimal  "amount",       :precision => 15, :scale => 2
    t.integer  "invoice_id"
    t.string   "invoice_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "discounts", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "document_users", :force => true do |t|
    t.integer  "user_id"
    t.integer  "document_id"
    t.boolean  "is_favorite", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "document_users", ["document_id"], :name => "index_document_users_on_document_id", :limit => {"document_id"=>nil}
  add_index "document_users", ["school_id"], :name => "index_document_users_on_school_id", :limit => {"school_id"=>nil}
  add_index "document_users", ["user_id", "document_id"], :name => "index_document_users_on_user_id_and_document_id", :limit => {"document_id"=>nil, "user_id"=>nil}
  add_index "document_users", ["user_id"], :name => "index_document_users_on_user_id", :limit => {"user_id"=>nil}

  create_table "documents", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.boolean  "is_deleted"
    t.integer  "folder_id"
    t.boolean  "is_favorite",             :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.integer  "school_id"
  end

  add_index "documents", ["school_id"], :name => "index_documents_on_school_id", :limit => {"school_id"=>nil}
  add_index "documents", ["user_id", "folder_id"], :name => "index_documents_on_user_id_and_folder_id", :limit => {"folder_id"=>nil, "user_id"=>nil}
  add_index "documents", ["user_id"], :name => "index_documents_on_user_id", :limit => {"user_id"=>nil}

  create_table "documents_users", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "document_id"
  end

  create_table "donation_additional_details", :force => true do |t|
    t.integer  "finance_donation_id"
    t.integer  "additional_field_id"
    t.string   "additional_info"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "donation_additional_details", ["school_id"], :name => "index_donation_additional_details_on_school_id", :limit => {"school_id"=>nil}

  create_table "donation_additional_field_options", :force => true do |t|
    t.integer  "donation_additional_field_id"
    t.string   "field_option"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "donation_additional_field_options", ["school_id"], :name => "index_donation_additional_field_options_on_school_id", :limit => {"school_id"=>nil}

  create_table "donation_additional_fields", :force => true do |t|
    t.string   "name"
    t.boolean  "status"
    t.boolean  "is_mandatory"
    t.string   "input_type"
    t.integer  "priority"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "donation_additional_fields", ["school_id"], :name => "index_donation_additional_fields_on_school_id", :limit => {"school_id"=>nil}

  create_table "eiop_settings", :force => true do |t|
    t.integer  "course_id"
    t.string   "grade_point"
    t.text     "pass_text"
    t.text     "eiop_text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "eiop_settings", ["school_id"], :name => "index_eiop_settings_on_school_id", :limit => {"school_id"=>nil}

  create_table "elective_groups", :force => true do |t|
    t.string   "name"
    t.integer  "batch_id"
    t.boolean  "is_deleted",               :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "end_date"
    t.boolean  "is_sixth_subject",         :default => false
    t.integer  "course_elective_group_id"
    t.integer  "priority"
    t.integer  "batch_subject_group_id"
    t.integer  "school_id"
  end

  add_index "elective_groups", ["batch_subject_group_id"], :name => "index_elective_groups_on_batch_subject_group_id", :limit => {"batch_subject_group_id"=>nil}
  add_index "elective_groups", ["course_elective_group_id"], :name => "index_elective_groups_on_course_elective_group_id", :limit => {"course_elective_group_id"=>nil}
  add_index "elective_groups", ["school_id"], :name => "index_elective_groups_on_school_id", :limit => {"school_id"=>nil}

  create_table "electives", :force => true do |t|
    t.integer  "elective_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "electives", ["school_id"], :name => "index_electives_on_school_id", :limit => {"school_id"=>nil}

  create_table "email_alerts", :force => true do |t|
    t.string   "model_name"
    t.boolean  "value"
    t.string   "mail_to"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  create_table "email_subscriptions", :force => true do |t|
    t.integer  "student_id"
    t.string   "name"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "email"
  end

  add_index "email_subscriptions", ["email"], :name => "index_email_subscriptions_on_email", :limit => {"email"=>nil}
  add_index "email_subscriptions", ["user_id"], :name => "index_email_subscriptions_on_user_id", :limit => {"user_id"=>nil}

  create_table "employee_additional_details", :force => true do |t|
    t.integer  "employee_id"
    t.integer  "additional_field_id"
    t.text     "additional_info"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "employee_additional_details", ["school_id"], :name => "index_employee_additional_details_on_school_id", :limit => {"school_id"=>nil}

  create_table "employee_additional_leaves", :force => true do |t|
    t.integer  "employee_id"
    t.integer  "employee_leave_type_id"
    t.integer  "employee_attendance_id"
    t.date     "attendance_date"
    t.string   "reason"
    t.boolean  "is_half_day",            :default => false
    t.boolean  "is_deductable",          :default => false
    t.boolean  "is_deducted",            :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "employee_additional_leaves", ["employee_id"], :name => "index_employee_additional_leaves_on_employee_id", :limit => {"employee_id"=>nil}
  add_index "employee_additional_leaves", ["employee_leave_type_id"], :name => "index_employee_additional_leaves_on_employee_leave_type_id", :limit => {"employee_leave_type_id"=>nil}
  add_index "employee_additional_leaves", ["school_id"], :name => "index_employee_additional_leaves_on_school_id", :limit => {"school_id"=>nil}

  create_table "employee_attendances", :force => true do |t|
    t.date     "attendance_date"
    t.integer  "employee_id"
    t.integer  "employee_leave_type_id"
    t.string   "reason"
    t.boolean  "is_half_day"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "apply_leave_id"
    t.integer  "employee_leave_id"
    t.integer  "school_id"
  end

  add_index "employee_attendances", ["apply_leave_id"], :name => "index_employee_attendances_on_apply_leave_id", :limit => {"apply_leave_id"=>nil}
  add_index "employee_attendances", ["employee_id"], :name => "index_employee_attendances_on_employee_id", :limit => {"employee_id"=>nil}
  add_index "employee_attendances", ["employee_leave_type_id"], :name => "index_employee_attendances_on_employee_leave_type_id", :limit => {"employee_leave_type_id"=>nil}
  add_index "employee_attendances", ["school_id"], :name => "index_employee_attendances_on_school_id", :limit => {"school_id"=>nil}

  create_table "employee_bank_details", :force => true do |t|
    t.integer  "employee_id"
    t.integer  "bank_field_id"
    t.string   "bank_info"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "employee_bank_details", ["school_id"], :name => "index_employee_bank_details_on_school_id", :limit => {"school_id"=>nil}

  create_table "employee_categories", :force => true do |t|
    t.string   "name"
    t.string   "prefix"
    t.boolean  "status"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "employee_categories", ["school_id"], :name => "index_employee_categories_on_school_id", :limit => {"school_id"=>nil}

  create_table "employee_department_events", :force => true do |t|
    t.integer  "event_id"
    t.integer  "employee_department_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "employee_department_events", ["employee_department_id"], :name => "index_employee_department_events_on_employee_department_id", :limit => {"employee_department_id"=>nil}
  add_index "employee_department_events", ["school_id"], :name => "index_employee_department_events_on_school_id", :limit => {"school_id"=>nil}

  create_table "employee_departments", :force => true do |t|
    t.string   "code"
    t.string   "name"
    t.boolean  "status"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "employee_departments", ["school_id"], :name => "index_employee_departments_on_school_id", :limit => {"school_id"=>nil}

  create_table "employee_grades", :force => true do |t|
    t.string   "name"
    t.integer  "priority"
    t.boolean  "status"
    t.integer  "max_hours_day"
    t.integer  "max_hours_week"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "employee_grades", ["school_id"], :name => "index_employee_grades_on_school_id", :limit => {"school_id"=>nil}

  create_table "employee_leave_balances", :force => true do |t|
    t.integer  "employee_id"
    t.integer  "employee_leave_type_id"
    t.decimal  "leave_balance",          :precision => 5, :scale => 1, :default => 0.0
    t.date     "reset_date"
    t.decimal  "leaves_added",           :precision => 5, :scale => 1, :default => 0.0
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_inactivated"
    t.decimal  "leaves_taken",           :precision => 5, :scale => 1, :default => 0.0
    t.decimal  "additional_leaves",      :precision => 5, :scale => 1, :default => 0.0
    t.integer  "leave_year_id"
    t.string   "action"
    t.string   "description"
  end

  add_index "employee_leave_balances", ["action"], :name => "index_by_action", :limit => {"action"=>nil}

  create_table "employee_leave_types", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.boolean  "is_active",                :default => true
    t.string   "max_leave_count"
    t.boolean  "carry_forward",            :default => false, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.boolean  "lop_enabled",              :default => false
    t.string   "max_carry_forward_leaves"
    t.integer  "carry_forward_type"
    t.date     "reset_date"
    t.integer  "creation_status",          :default => 1
    t.integer  "credit_frequency"
    t.integer  "days_count"
    t.string   "credit_type"
    t.integer  "school_id"
  end

  add_index "employee_leave_types", ["school_id"], :name => "index_employee_leave_types_on_school_id", :limit => {"school_id"=>nil}

  create_table "employee_leaves", :force => true do |t|
    t.integer  "employee_id"
    t.integer  "employee_leave_type_id"
    t.decimal  "leave_count",            :precision => 5, :scale => 1, :default => 0.0
    t.decimal  "leave_taken",            :precision => 5, :scale => 1, :default => 0.0
    t.datetime "reseted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "additional_leaves",      :precision => 5, :scale => 1, :default => 0.0
    t.date     "reset_date"
    t.integer  "leave_group_id"
    t.boolean  "is_active",                                            :default => true
    t.boolean  "is_additional",                                        :default => false
    t.date     "credited_at"
    t.boolean  "mark_for_credit",                                      :default => false
    t.boolean  "mark_for_remove",                                      :default => false
    t.integer  "school_id"
  end

  add_index "employee_leaves", ["employee_id"], :name => "index_employee_leaves_on_employee_id", :limit => {"employee_id"=>nil}
  add_index "employee_leaves", ["leave_group_id"], :name => "index_employee_leaves_on_leave_group_id", :limit => {"leave_group_id"=>nil}
  add_index "employee_leaves", ["school_id"], :name => "index_employee_leaves_on_school_id", :limit => {"school_id"=>nil}

  create_table "employee_lops", :force => true do |t|
    t.integer  "payroll_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "lop_as_deduction", :default => true
    t.integer  "school_id"
  end

  add_index "employee_lops", ["payroll_group_id"], :name => "index_employee_lops_on_payroll_group_id", :limit => {"payroll_group_id"=>nil}
  add_index "employee_lops", ["school_id"], :name => "index_employee_lops_on_school_id", :limit => {"school_id"=>nil}

  create_table "employee_overtimes", :force => true do |t|
    t.integer  "payroll_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "employee_overtimes", ["school_id"], :name => "index_employee_overtimes_on_school_id", :limit => {"school_id"=>nil}

  create_table "employee_payslip_categories", :force => true do |t|
    t.integer  "employee_payslip_id"
    t.integer  "payroll_category_id"
    t.string   "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "employee_payslip_categories", ["employee_payslip_id"], :name => "index_employee_payslip_categories_on_employee_payslip_id", :limit => {"employee_payslip_id"=>nil}
  add_index "employee_payslip_categories", ["payroll_category_id"], :name => "index_employee_payslip_categories_on_payroll_category_id", :limit => {"payroll_category_id"=>nil}
  add_index "employee_payslip_categories", ["school_id"], :name => "index_employee_payslip_categories_on_school_id", :limit => {"school_id"=>nil}

  create_table "employee_payslips", :force => true do |t|
    t.integer  "employee_id"
    t.string   "employee_type"
    t.boolean  "is_approved",              :default => false
    t.integer  "approver_id"
    t.boolean  "is_rejected",              :default => false
    t.integer  "rejector_id"
    t.string   "reason"
    t.string   "net_pay"
    t.string   "gross_salary"
    t.string   "lop"
    t.string   "days_count"
    t.integer  "payslips_date_range_id"
    t.integer  "finance_transaction_id"
    t.integer  "revision_number"
    t.string   "lop_amount"
    t.string   "working_days"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "total_earnings"
    t.string   "total_deductions"
    t.boolean  "deducted_from_categories", :default => false
    t.integer  "payroll_revision_id"
    t.integer  "financial_year_id"
    t.text     "employee_details"
    t.text     "leave_details"
    t.integer  "school_id"
  end

  add_index "employee_payslips", ["employee_id", "employee_type"], :name => "index_employee_payslips_on_employee_id_and_employee_type", :limit => {"employee_id"=>nil, "employee_type"=>nil}
  add_index "employee_payslips", ["finance_transaction_id"], :name => "index_employee_payslips_on_finance_transaction_id", :limit => {"finance_transaction_id"=>nil}
  add_index "employee_payslips", ["financial_year_id"], :name => "index_by_financial_year", :limit => {"financial_year_id"=>nil}
  add_index "employee_payslips", ["is_approved", "is_rejected"], :name => "index_employee_payslips_on_is_approved_and_is_rejected", :limit => {"is_rejected"=>nil, "is_approved"=>nil}
  add_index "employee_payslips", ["is_approved"], :name => "index_employee_payslips_on_is_approved", :limit => {"is_approved"=>nil}
  add_index "employee_payslips", ["is_rejected"], :name => "index_employee_payslips_on_is_rejected", :limit => {"is_rejected"=>nil}
  add_index "employee_payslips", ["payslips_date_range_id", "employee_id", "employee_type"], :name => "employee_payslip_uniqueness", :unique => true, :limit => {"employee_id"=>nil, "payslips_date_range_id"=>nil, "employee_type"=>nil}
  add_index "employee_payslips", ["payslips_date_range_id"], :name => "index_employee_payslips_on_payslips_date_range_id", :limit => {"payslips_date_range_id"=>nil}
  add_index "employee_payslips", ["school_id"], :name => "index_employee_payslips_on_school_id", :limit => {"school_id"=>nil}

  create_table "employee_positions", :force => true do |t|
    t.string   "name"
    t.integer  "employee_category_id"
    t.boolean  "status"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "employee_positions", ["school_id"], :name => "index_employee_positions_on_school_id", :limit => {"school_id"=>nil}

  create_table "employee_salary_structure_components", :force => true do |t|
    t.integer  "employee_salary_structure_id"
    t.integer  "payroll_category_id"
    t.string   "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "employee_salary_structure_components", ["employee_salary_structure_id"], :name => "by_structure_id", :limit => {"employee_salary_structure_id"=>nil}
  add_index "employee_salary_structure_components", ["payroll_category_id"], :name => "by_cat_id", :limit => {"payroll_category_id"=>nil}
  add_index "employee_salary_structure_components", ["school_id"], :name => "index_employee_salary_structure_components_on_school_id", :limit => {"school_id"=>nil}

  create_table "employee_salary_structures", :force => true do |t|
    t.integer  "employee_id"
    t.integer  "payroll_category_id"
    t.string   "amount"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "gross_salary"
    t.string   "net_pay"
    t.integer  "payroll_group_id"
    t.integer  "revision_number"
    t.integer  "latest_revision_id"
    t.integer  "school_id"
  end

  add_index "employee_salary_structures", ["employee_id"], :name => "index_employee_salary_structures_on_employee_id", :limit => {"employee_id"=>nil}
  add_index "employee_salary_structures", ["payroll_group_id"], :name => "index_employee_salary_structures_on_payroll_group_id", :limit => {"payroll_group_id"=>nil}
  add_index "employee_salary_structures", ["school_id"], :name => "index_employee_salary_structures_on_school_id", :limit => {"school_id"=>nil}

  create_table "employees", :force => true do |t|
    t.integer  "employee_category_id"
    t.string   "employee_number"
    t.date     "joining_date"
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.string   "gender"
    t.string   "job_title"
    t.integer  "employee_position_id"
    t.integer  "employee_department_id"
    t.integer  "reporting_manager_id"
    t.integer  "employee_grade_id"
    t.string   "qualification"
    t.text     "experience_detail"
    t.integer  "experience_year"
    t.integer  "experience_month"
    t.boolean  "status"
    t.string   "status_description"
    t.date     "date_of_birth"
    t.string   "marital_status"
    t.integer  "children_count"
    t.string   "father_name"
    t.string   "mother_name"
    t.string   "husband_name"
    t.string   "blood_group"
    t.integer  "nationality_id"
    t.string   "home_address_line1"
    t.string   "home_address_line2"
    t.string   "home_city"
    t.string   "home_state"
    t.integer  "home_country_id"
    t.string   "home_pin_code"
    t.string   "office_address_line1"
    t.string   "office_address_line2"
    t.string   "office_city"
    t.string   "office_state"
    t.integer  "office_country_id"
    t.string   "office_pin_code"
    t.string   "office_phone1"
    t.string   "office_phone2"
    t.string   "mobile_phone"
    t.string   "home_phone"
    t.string   "email"
    t.string   "fax"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.binary   "photo_data",             :limit => 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "photo_file_size"
    t.integer  "user_id"
    t.datetime "photo_updated_at"
    t.integer  "school_id"
    t.date     "last_reset_date"
    t.date     "last_credit_date"
    t.string   "library_card"
  end

  add_index "employees", ["employee_department_id"], :name => "index_employees_on_employee_department_id", :limit => {"employee_department_id"=>nil}
  add_index "employees", ["employee_number", "school_id"], :name => "employee_number_unique_index", :unique => true, :limit => {"school_id"=>nil, "employee_number"=>nil}
  add_index "employees", ["employee_number"], :name => "index_employees_on_employee_number", :limit => {"employee_number"=>"10"}
  add_index "employees", ["school_id"], :name => "index_employees_on_school_id", :limit => {"school_id"=>nil}
  add_index "employees", ["user_id"], :name => "index_employees_on_user_id", :limit => {"user_id"=>nil}

  create_table "employees_subjects", :force => true do |t|
    t.integer  "employee_id"
    t.integer  "subject_id"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "employees_subjects", ["school_id"], :name => "index_employees_subjects_on_school_id", :limit => {"school_id"=>nil}
  add_index "employees_subjects", ["subject_id"], :name => "index_employees_subjects_on_subject_id", :limit => {"subject_id"=>nil}

  create_table "events", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "start_date"
    t.datetime "end_date"
    t.boolean  "is_common",   :default => false
    t.boolean  "is_holiday",  :default => false
    t.boolean  "is_exam",     :default => false
    t.boolean  "is_due",      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "origin_id"
    t.string   "origin_type"
    t.integer  "school_id"
  end

  add_index "events", ["is_common", "is_holiday", "is_exam"], :name => "index_events_on_is_common_and_is_holiday_and_is_exam", :limit => {"is_exam"=>nil, "is_holiday"=>nil, "is_common"=>nil}
  add_index "events", ["origin_id", "origin_type"], :name => "polymorphic_origin_index", :limit => {"origin_id"=>nil, "origin_type"=>nil}
  add_index "events", ["school_id"], :name => "index_events_on_school_id", :limit => {"school_id"=>nil}

  create_table "exam_group_fa_statuses", :force => true do |t|
    t.integer  "exam_group_id"
    t.string   "fa_group"
    t.boolean  "send_or_resend_sms", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "exam_group_fa_statuses", ["school_id"], :name => "index_exam_group_fa_statuses_on_school_id", :limit => {"school_id"=>nil}

  create_table "exam_groups", :force => true do |t|
    t.string   "name"
    t.integer  "batch_id"
    t.string   "exam_type"
    t.boolean  "is_published",          :default => false
    t.boolean  "result_published",      :default => false
    t.date     "exam_date"
    t.boolean  "is_final_exam",         :default => false, :null => false
    t.integer  "cce_exam_category_id"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "icse_exam_category_id"
    t.integer  "course_exam_group_id"
    t.integer  "school_id"
  end

  add_index "exam_groups", ["course_exam_group_id"], :name => "index_exam_groups_on_course_exam_group_id", :limit => {"course_exam_group_id"=>nil}
  add_index "exam_groups", ["icse_exam_category_id"], :name => "index_exam_groups_on_icse_exam_category_id", :limit => {"icse_exam_category_id"=>nil}
  add_index "exam_groups", ["school_id"], :name => "index_exam_groups_on_school_id", :limit => {"school_id"=>nil}

  create_table "exam_scores", :force => true do |t|
    t.integer  "student_id"
    t.integer  "exam_id"
    t.decimal  "marks",            :precision => 7, :scale => 2
    t.integer  "grading_level_id"
    t.string   "remarks"
    t.boolean  "is_failed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "exam_scores", ["exam_id", "student_id"], :name => "exam_scores_unique_index", :unique => true, :limit => {"student_id"=>nil, "exam_id"=>nil}
  add_index "exam_scores", ["school_id"], :name => "index_exam_scores_on_school_id", :limit => {"school_id"=>nil}
  add_index "exam_scores", ["student_id", "exam_id"], :name => "index_exam_scores_on_student_id_and_exam_id", :limit => {"student_id"=>nil, "exam_id"=>nil}

  create_table "exams", :force => true do |t|
    t.integer  "exam_group_id"
    t.integer  "subject_id"
    t.datetime "start_time"
    t.datetime "end_time"
    t.decimal  "maximum_marks",    :precision => 10, :scale => 2
    t.decimal  "minimum_marks",    :precision => 10, :scale => 2
    t.integer  "grading_level_id"
    t.integer  "weightage",                                       :default => 0
    t.integer  "event_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "exams", ["exam_group_id", "subject_id"], :name => "index_exams_on_exam_group_id_and_subject_id", :limit => {"exam_group_id"=>nil, "subject_id"=>nil}
  add_index "exams", ["school_id"], :name => "index_exams_on_school_id", :limit => {"school_id"=>nil}

  create_table "export_structures", :force => true do |t|
    t.string   "model_name"
    t.text     "query"
    t.string   "template"
    t.string   "plugin_name"
    t.text     "csv_header_order"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "exports", :force => true do |t|
    t.text     "structure"
    t.string   "name"
    t.string   "model"
    t.text     "associated_columns"
    t.text     "join_columns"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "exports", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "fa_criterias", :force => true do |t|
    t.string   "fa_name"
    t.string   "desc"
    t.integer  "fa_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_order"
    t.boolean  "is_deleted",  :default => false
    t.float    "max_marks",   :default => 100.0
    t.string   "formula_key"
    t.integer  "school_id"
  end

  add_index "fa_criterias", ["fa_group_id"], :name => "index_fa_criterias_on_fa_group_id", :limit => {"fa_group_id"=>nil}
  add_index "fa_criterias", ["school_id"], :name => "index_fa_criterias_on_school_id", :limit => {"school_id"=>nil}

  create_table "fa_groups", :force => true do |t|
    t.string   "name"
    t.text     "desc"
    t.integer  "cce_exam_category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "cce_grade_set_id"
    t.float    "max_marks",            :default => 100.0
    t.boolean  "is_deleted",           :default => false
    t.integer  "di_formula"
    t.string   "criteria_formula"
    t.integer  "school_id"
  end

  add_index "fa_groups", ["school_id"], :name => "index_fa_groups_on_school_id", :limit => {"school_id"=>nil}

  create_table "fa_groups_subjects", :id => false, :force => true do |t|
    t.integer "subject_id"
    t.integer "fa_group_id"
  end

  add_index "fa_groups_subjects", ["fa_group_id", "subject_id"], :name => "score_index", :limit => {"fa_group_id"=>nil, "subject_id"=>nil}
  add_index "fa_groups_subjects", ["fa_group_id"], :name => "index_fa_groups_subjects_on_fa_group_id", :limit => {"fa_group_id"=>nil}
  add_index "fa_groups_subjects", ["subject_id"], :name => "index_fa_groups_subjects_on_subject_id", :limit => {"subject_id"=>nil}

  create_table "feature_access_settings", :force => true do |t|
    t.string   "feature_name"
    t.boolean  "parent_can_access", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "feature_access_settings", ["school_id"], :name => "index_feature_access_settings_on_school_id", :limit => {"school_id"=>nil}

  create_table "features", :force => true do |t|
    t.string   "feature_key"
    t.boolean  "is_enabled",  :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fee_accounts", :force => true do |t|
    t.string   "name",                           :null => false
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_deleted",  :default => false
    t.integer  "school_id"
  end

  add_index "fee_accounts", ["is_deleted"], :name => "index_fee_accounts_on_is_deleted", :limit => {"is_deleted"=>nil}
  add_index "fee_accounts", ["school_id"], :name => "index_fee_accounts_on_school_id", :limit => {"school_id"=>nil}

  create_table "fee_collection_batches", :force => true do |t|
    t.integer  "finance_fee_collection_id"
    t.integer  "batch_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "fee_collection_batches", ["batch_id"], :name => "index_fee_collection_batches_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "fee_collection_batches", ["finance_fee_collection_id"], :name => "index_fee_collection_batches_on_finance_fee_collection_id", :limit => {"finance_fee_collection_id"=>nil}
  add_index "fee_collection_batches", ["school_id"], :name => "index_fee_collection_batches_on_school_id", :limit => {"school_id"=>nil}

  create_table "fee_collection_discounts", :force => true do |t|
    t.string   "type"
    t.string   "name"
    t.integer  "receiver_id"
    t.integer  "finance_fee_collection_id"
    t.decimal  "discount",                  :precision => 15, :scale => 4
    t.boolean  "is_amount",                                                :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "fee_collection_discounts", ["school_id"], :name => "index_fee_collection_discounts_on_school_id", :limit => {"school_id"=>nil}

  create_table "fee_collection_particulars", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.decimal  "amount",                    :precision => 12, :scale => 4
    t.integer  "finance_fee_collection_id"
    t.integer  "student_category_id"
    t.string   "admission_no"
    t.integer  "student_id"
    t.boolean  "is_deleted",                                               :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "fee_collection_particulars", ["school_id"], :name => "index_fee_collection_particulars_on_school_id", :limit => {"school_id"=>nil}

  create_table "fee_discounts", :force => true do |t|
    t.string   "type"
    t.string   "name"
    t.integer  "receiver_id"
    t.integer  "finance_fee_category_id"
    t.decimal  "discount",                :precision => 15, :scale => 4
    t.boolean  "is_amount",                                              :default => false
    t.string   "receiver_type"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "batch_id"
    t.boolean  "is_deleted",                                             :default => false
    t.string   "master_receiver_type"
    t.integer  "master_receiver_id"
    t.boolean  "is_instant",                                             :default => false
    t.integer  "multi_fee_discount_id"
    t.integer  "master_fee_discount_id"
    t.integer  "finance_transaction_id"
    t.integer  "school_id"
  end

  add_index "fee_discounts", ["finance_fee_category_id"], :name => "index_fee_discounts_on_finance_fee_category_id", :limit => {"finance_fee_category_id"=>nil}
  add_index "fee_discounts", ["finance_transaction_id"], :name => "index_on_finance_transaction_id", :limit => {"finance_transaction_id"=>nil}
  add_index "fee_discounts", ["master_fee_discount_id"], :name => "index_by_master_fee_discount", :limit => {"master_fee_discount_id"=>nil}
  add_index "fee_discounts", ["multi_fee_discount_id"], :name => "index_by_multi_fee_discount", :limit => {"multi_fee_discount_id"=>nil}
  add_index "fee_discounts", ["school_id"], :name => "index_fee_discounts_on_school_id", :limit => {"school_id"=>nil}

  create_table "fee_invoices", :force => true do |t|
    t.integer  "fee_id",                           :null => false
    t.string   "fee_type",                         :null => false
    t.string   "invoice_number",                   :null => false
    t.boolean  "is_active",      :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.text     "invoice_data"
  end

  add_index "fee_invoices", ["fee_type", "fee_id"], :name => "index_by_fee_type_and_fee_id", :limit => {"fee_type"=>nil, "fee_id"=>nil}
  add_index "fee_invoices", ["invoice_number", "school_id"], :name => "school_invoice_number_uniqueness", :unique => true, :limit => {"invoice_number"=>nil, "school_id"=>nil}
  add_index "fee_invoices", ["invoice_number"], :name => "index_by_invoice_number", :limit => {"invoice_number"=>nil}

  create_table "fee_receipt_templates", :force => true do |t|
    t.string   "name",                                                    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "header_content",                    :limit => 2147483647
    t.text     "footer_content"
    t.text     "header_content_a5_portrait",        :limit => 2147483647
    t.text     "header_content_thermal_responsive", :limit => 2147483647
    t.integer  "school_id"
  end

  add_index "fee_receipt_templates", ["school_id"], :name => "index_fee_receipt_templates_on_school_id", :limit => {"school_id"=>nil}

  create_table "fee_refunds", :force => true do |t|
    t.integer  "finance_fee_id"
    t.text     "reason"
    t.decimal  "amount",                 :precision => 15, :scale => 4
    t.integer  "finance_transaction_id"
    t.integer  "refund_rule_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "fee_refunds", ["finance_fee_id"], :name => "index_fee_refunds_on_finance_fee_id", :limit => {"finance_fee_id"=>nil}
  add_index "fee_refunds", ["finance_transaction_id"], :name => "index_by_ft_id", :limit => {"finance_transaction_id"=>nil}
  add_index "fee_refunds", ["school_id"], :name => "index_fee_refunds_on_school_id", :limit => {"school_id"=>nil}

  create_table "fee_transactions", :force => true do |t|
    t.integer  "finance_fee_id"
    t.integer  "finance_transaction_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "fee_transactions", ["finance_fee_id", "finance_transaction_id"], :name => "finance_transaction_index", :limit => {"finance_fee_id"=>nil, "finance_transaction_id"=>nil}
  add_index "fee_transactions", ["school_id"], :name => "index_fee_transactions_on_school_id", :limit => {"school_id"=>nil}

  create_table "finance_category_accounts", :force => true do |t|
    t.integer  "category_id"
    t.string   "category_type"
    t.integer  "fee_account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "finance_category_accounts", ["school_id"], :name => "index_finance_category_accounts_on_school_id", :limit => {"school_id"=>nil}

  create_table "finance_category_receipt_sets", :force => true do |t|
    t.integer  "category_id"
    t.string   "category_type"
    t.integer  "receipt_number_set_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "finance_category_receipt_sets", ["category_id", "category_type"], :name => "index_by_category", :limit => {"category_type"=>nil, "category_id"=>nil}
  add_index "finance_category_receipt_sets", ["receipt_number_set_id"], :name => "index_by_receipt_number_set", :limit => {"receipt_number_set_id"=>nil}
  add_index "finance_category_receipt_sets", ["school_id"], :name => "index_finance_category_receipt_sets_on_school_id", :limit => {"school_id"=>nil}

  create_table "finance_category_receipt_templates", :force => true do |t|
    t.integer  "category_id"
    t.string   "category_type"
    t.integer  "fee_receipt_template_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "finance_category_receipt_templates", ["school_id"], :name => "index_finance_category_receipt_templates_on_school_id", :limit => {"school_id"=>nil}

  create_table "finance_donations", :force => true do |t|
    t.string   "donor"
    t.string   "description"
    t.decimal  "amount",            :precision => 15, :scale => 4
    t.integer  "transaction_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "transaction_date"
    t.integer  "financial_year_id"
    t.integer  "school_id"
  end

  add_index "finance_donations", ["financial_year_id"], :name => "index_by_financial_year", :limit => {"financial_year_id"=>nil}
  add_index "finance_donations", ["school_id"], :name => "index_finance_donations_on_school_id", :limit => {"school_id"=>nil}

  create_table "finance_fee_categories", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "batch_id"
    t.boolean  "is_deleted",        :default => false, :null => false
    t.boolean  "is_master",         :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "financial_year_id"
    t.integer  "school_id"
  end

  add_index "finance_fee_categories", ["financial_year_id"], :name => "index_by_financial_year", :limit => {"financial_year_id"=>nil}
  add_index "finance_fee_categories", ["school_id"], :name => "index_finance_fee_categories_on_school_id", :limit => {"school_id"=>nil}

  create_table "finance_fee_collections", :force => true do |t|
    t.string   "name"
    t.date     "start_date"
    t.date     "end_date"
    t.date     "due_date"
    t.integer  "fee_category_id"
    t.integer  "batch_id"
    t.boolean  "is_deleted",        :default => false,          :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "fine_id"
    t.boolean  "tax_enabled",       :default => false
    t.string   "discount_mode",     :default => "OLD_DISCOUNT"
    t.boolean  "invoice_enabled",   :default => false
    t.integer  "fee_account_id"
    t.integer  "financial_year_id"
    t.integer  "school_id"
  end

  add_index "finance_fee_collections", ["batch_id"], :name => "index_finance_fee_collections_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "finance_fee_collections", ["due_date"], :name => "index_finance_fee_collections_on_due_date", :limit => {"due_date"=>nil}
  add_index "finance_fee_collections", ["fee_account_id"], :name => "index_by_fee_account_id", :limit => {"fee_account_id"=>nil}
  add_index "finance_fee_collections", ["fee_category_id"], :name => "index_finance_fee_collections_on_fee_category_id", :limit => {"fee_category_id"=>nil}
  add_index "finance_fee_collections", ["financial_year_id"], :name => "index_by_financial_year", :limit => {"financial_year_id"=>nil}
  add_index "finance_fee_collections", ["is_deleted", "due_date"], :name => "is_deleted_and_due_date", :limit => {"due_date"=>nil, "is_deleted"=>nil}
  add_index "finance_fee_collections", ["is_deleted"], :name => "index_finance_fee_collections_on_is_deleted", :limit => {"is_deleted"=>nil}
  add_index "finance_fee_collections", ["school_id"], :name => "index_finance_fee_collections_on_school_id", :limit => {"school_id"=>nil}

  create_table "finance_fee_discounts", :force => true do |t|
    t.integer  "finance_fee_particular_id",                                :null => false
    t.integer  "finance_fee_id",                                           :null => false
    t.integer  "fee_discount_id"
    t.decimal  "discount_amount",           :precision => 15, :scale => 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "finance_fee_discounts", ["finance_fee_id", "fee_discount_id"], :name => "index_by_fee_id_and_discount_id", :limit => {"finance_fee_id"=>nil, "fee_discount_id"=>nil}
  add_index "finance_fee_discounts", ["finance_fee_id", "finance_fee_particular_id", "fee_discount_id"], :name => "index_by_fee_id_and_particular_id_and_discount_id", :limit => {"finance_fee_id"=>nil, "finance_fee_particular_id"=>nil, "fee_discount_id"=>nil}
  add_index "finance_fee_discounts", ["finance_fee_particular_id"], :name => "index_finance_fee_discounts_on_finance_fee_particular_id", :limit => {"finance_fee_particular_id"=>nil}

  create_table "finance_fee_particulars", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.decimal  "amount",                   :precision => 15, :scale => 4
    t.integer  "finance_fee_category_id"
    t.integer  "student_category_id"
    t.string   "admission_no"
    t.integer  "student_id"
    t.boolean  "is_deleted",                                              :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "receiver_id"
    t.string   "receiver_type"
    t.integer  "batch_id"
    t.boolean  "is_instant",                                              :default => false
    t.integer  "master_fee_particular_id"
    t.integer  "school_id"
  end

  add_index "finance_fee_particulars", ["finance_fee_category_id"], :name => "index_finance_fee_particulars_on_finance_fee_category_id", :limit => {"finance_fee_category_id"=>nil}
  add_index "finance_fee_particulars", ["master_fee_particular_id"], :name => "index_by_master_fee_particular", :limit => {"master_fee_particular_id"=>nil}
  add_index "finance_fee_particulars", ["school_id"], :name => "index_finance_fee_particulars_on_school_id", :limit => {"school_id"=>nil}

  create_table "finance_fee_structure_elements", :force => true do |t|
    t.decimal  "amount",              :precision => 15, :scale => 4
    t.string   "label"
    t.integer  "batch_id"
    t.integer  "student_category_id"
    t.integer  "student_id"
    t.integer  "parent_id"
    t.integer  "fee_collection_id"
    t.boolean  "deleted",                                            :default => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "finance_fee_structure_elements", ["school_id"], :name => "index_finance_fee_structure_elements_on_school_id", :limit => {"school_id"=>nil}

  create_table "finance_fees", :force => true do |t|
    t.integer  "fee_collection_id"
    t.string   "transaction_id"
    t.integer  "student_id"
    t.boolean  "is_paid",                                            :default => false
    t.decimal  "balance",             :precision => 15, :scale => 4, :default => 0.0
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "batch_id"
    t.integer  "student_category_id"
    t.decimal  "particular_total",    :precision => 15, :scale => 4
    t.decimal  "discount_amount",     :precision => 15, :scale => 4
    t.decimal  "tax_amount",          :precision => 15, :scale => 4, :default => 0.0
    t.boolean  "tax_enabled",                                        :default => false
    t.boolean  "is_fine_paid"
    t.decimal  "balance_fine",        :precision => 15, :scale => 2
    t.boolean  "is_fine_waiver",                                     :default => false
    t.integer  "school_id"
  end

  add_index "finance_fees", ["balance"], :name => "index_finance_fees_on_balance", :limit => {"balance"=>nil}
  add_index "finance_fees", ["batch_id"], :name => "index_finance_fees_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "finance_fees", ["fee_collection_id", "student_id"], :name => "index_finance_fees_on_fee_collection_id_and_student_id", :limit => {"student_id"=>nil, "fee_collection_id"=>nil}
  add_index "finance_fees", ["is_paid", "student_id"], :name => "index_on_is_paid_and_student", :limit => {"student_id"=>nil, "is_paid"=>nil}
  add_index "finance_fees", ["school_id"], :name => "index_finance_fees_on_school_id", :limit => {"school_id"=>nil}
  add_index "finance_fees", ["student_id", "fee_collection_id", "is_paid"], :name => "index_on_is_paid", :limit => {"fee_collection_id"=>nil, "student_id"=>nil, "is_paid"=>nil}
  add_index "finance_fees", ["student_id", "fee_collection_id"], :name => "finance_fee_uniqueness", :unique => true, :limit => {"fee_collection_id"=>nil, "student_id"=>nil}

  create_table "finance_payments", :force => true do |t|
    t.string   "fee_payment_type"
    t.integer  "fee_payment_id"
    t.integer  "finance_transaction_id"
    t.integer  "payment_id"
    t.string   "fee_collection_type"
    t.integer  "fee_collection_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "finance_payments", ["payment_id"], :name => "by_payment_id", :limit => {"payment_id"=>nil}

  create_table "finance_transaction_categories", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.boolean  "is_income"
    t.boolean  "deleted",         :default => false, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "tally_ledger_id"
    t.integer  "school_id"
  end

  add_index "finance_transaction_categories", ["school_id"], :name => "index_finance_transaction_categories_on_school_id", :limit => {"school_id"=>nil}

  create_table "finance_transaction_fines", :force => true do |t|
    t.integer  "finance_transaction_id",    :null => false
    t.integer  "multi_transaction_fine_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "finance_transaction_fines", ["finance_transaction_id", "multi_transaction_fine_id"], :name => "index_by_transaction_and_fine_id", :limit => {"multi_transaction_fine_id"=>nil, "finance_transaction_id"=>nil}
  add_index "finance_transaction_fines", ["school_id"], :name => "index_finance_transaction_fines_on_school_id", :limit => {"school_id"=>nil}

  create_table "finance_transaction_ledgers", :force => true do |t|
    t.decimal  "amount",                                  :precision => 15, :scale => 4
    t.string   "payment_mode"
    t.text     "payment_note"
    t.date     "transaction_date"
    t.integer  "payee_id"
    t.string   "payee_type"
    t.string   "transaction_type",  :limit => 10
    t.string   "receipt_no"
    t.string   "status",                                                                 :default => "ACTIVE"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "transaction_mode",  :limit => 10
    t.string   "reference_no"
    t.integer  "school_id"
    t.text     "transaction_data",  :limit => 2147483647
    t.integer  "financial_year_id"
    t.boolean  "is_waiver",                                                              :default => false
  end

  add_index "finance_transaction_ledgers", ["financial_year_id"], :name => "index_by_financial_year", :limit => {"financial_year_id"=>nil}
  add_index "finance_transaction_ledgers", ["payee_type", "payee_id", "status"], :name => "index_by_payee_and_status", :limit => {"payee_type"=>nil, "payee_id"=>nil, "status"=>nil}
  add_index "finance_transaction_ledgers", ["receipt_no", "school_id"], :name => "index_finance_transaction_ledgers_on_receipt_no_and_school_id", :unique => true, :limit => {"receipt_no"=>nil, "school_id"=>nil}
  add_index "finance_transaction_ledgers", ["receipt_no"], :name => "index_by_receipt_no", :limit => {"receipt_no"=>nil}
  add_index "finance_transaction_ledgers", ["school_id"], :name => "index_finance_transaction_ledgers_on_school_id", :limit => {"school_id"=>nil}
  add_index "finance_transaction_ledgers", ["status"], :name => "index_by_status", :limit => {"status"=>nil}
  add_index "finance_transaction_ledgers", ["transaction_mode"], :name => "index_by_transaction_mode", :limit => {"transaction_mode"=>nil}

  create_table "finance_transaction_receipt_records", :force => true do |t|
    t.integer  "finance_transaction_id"
    t.integer  "transaction_receipt_id"
    t.integer  "fee_account_id"
    t.integer  "fee_receipt_template_id"
    t.integer  "precision_count"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "receipt_data",            :limit => 2147483647
  end

  add_index "finance_transaction_receipt_records", ["fee_account_id"], :name => "index_by_fee_account", :limit => {"fee_account_id"=>nil}
  add_index "finance_transaction_receipt_records", ["finance_transaction_id", "transaction_receipt_id"], :name => "index_by_transaction_and_receipt", :limit => {"finance_transaction_id"=>nil, "transaction_receipt_id"=>nil}
  add_index "finance_transaction_receipt_records", ["finance_transaction_id"], :name => "index_on_finance_transaction_id", :limit => {"finance_transaction_id"=>nil}
  add_index "finance_transaction_receipt_records", ["school_id"], :name => "index_finance_transaction_receipt_records_on_school_id", :limit => {"school_id"=>nil}
  add_index "finance_transaction_receipt_records", ["transaction_receipt_id"], :name => "index_on_transaction_receipt_id", :limit => {"transaction_receipt_id"=>nil}

  create_table "finance_transaction_triggers", :force => true do |t|
    t.integer  "finance_category_id"
    t.decimal  "percentage",          :precision => 8, :scale => 2
    t.string   "title"
    t.string   "description"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "finance_transaction_triggers", ["school_id"], :name => "index_finance_transaction_triggers_on_school_id", :limit => {"school_id"=>nil}

  create_table "finance_transactions", :force => true do |t|
    t.string   "title"
    t.string   "description"
    t.decimal  "amount",                             :precision => 15, :scale => 4
    t.boolean  "fine_included",                                                     :default => false
    t.integer  "category_id"
    t.integer  "student_id"
    t.integer  "finance_fees_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "transaction_date"
    t.decimal  "fine_amount",                        :precision => 15, :scale => 4, :default => 0.0
    t.integer  "master_transaction_id",                                             :default => 0
    t.integer  "finance_id"
    t.string   "finance_type"
    t.integer  "payee_id"
    t.string   "payee_type"
    t.string   "receipt_no"
    t.string   "voucher_no"
    t.string   "payment_mode"
    t.text     "payment_note"
    t.integer  "user_id"
    t.integer  "batch_id"
    t.decimal  "auto_fine",                          :precision => 15, :scale => 4
    t.string   "reference_no"
    t.string   "trans_type",                                                        :default => "collection_wise"
    t.integer  "school_id"
    t.integer  "transaction_stamp",     :limit => 8
    t.integer  "transaction_ledger_id"
    t.decimal  "tax_amount",                         :precision => 15, :scale => 4, :default => 0.0
    t.boolean  "tax_included",                                                      :default => false
    t.string   "bank_name"
    t.string   "cheque_date"
    t.integer  "financial_year_id"
    t.boolean  "wallet_amount_applied",                                             :default => false
    t.decimal  "wallet_amount",                      :precision => 15, :scale => 2, :default => 0.0
    t.boolean  "fine_waiver",                                                       :default => false
    t.integer  "lastvchid"
  end

  add_index "finance_transactions", ["batch_id"], :name => "index_finance_transactions_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "finance_transactions", ["category_id"], :name => "index_on_finance_transaction_category", :limit => {"category_id"=>nil}
  add_index "finance_transactions", ["finance_id", "finance_type"], :name => "index_finance_transactions_on_finance_id_and_finance_type", :limit => {"finance_id"=>nil, "finance_type"=>nil}
  add_index "finance_transactions", ["financial_year_id"], :name => "by_fy_id", :limit => {"financial_year_id"=>nil}
  add_index "finance_transactions", ["id", "transaction_stamp"], :name => "index_on_finance_transaction_id_and_transaction_stamp", :limit => {"id"=>nil, "transaction_stamp"=>nil}
  add_index "finance_transactions", ["payee_id", "payee_type"], :name => "index_finance_transactions_on_payee_id_and_payee_type", :limit => {"payee_type"=>nil, "payee_id"=>nil}
  add_index "finance_transactions", ["receipt_no", "school_id"], :name => "index_finance_transactions_on_receipt_no_and_school_id", :unique => true, :limit => {"receipt_no"=>nil, "school_id"=>nil}
  add_index "finance_transactions", ["receipt_no", "voucher_no"], :name => "index_finance_transactions_on_receipt_no_and_voucher_no", :limit => {"receipt_no"=>nil, "voucher_no"=>nil}
  add_index "finance_transactions", ["transaction_date"], :name => "index_finance_transactions_on_transaction_date", :limit => {"transaction_date"=>nil}
  add_index "finance_transactions", ["transaction_ledger_id"], :name => "index_by_transaction_leger_id", :limit => {"transaction_ledger_id"=>nil}
  add_index "finance_transactions", ["wallet_amount_applied"], :name => "index_on_wallet_amount_applied", :limit => {"wallet_amount_applied"=>nil}

  create_table "finance_transactions_multi_transaction_fines", :id => false, :force => true do |t|
    t.integer "finance_transaction_id"
    t.integer "multi_transaction_fine_id"
  end

  create_table "financial_years", :force => true do |t|
    t.string   "name"
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "school_id"
    t.boolean  "is_active",  :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "financial_years", ["school_id"], :name => "index_financial_years_on_school_id", :limit => {"school_id"=>nil}

  create_table "fine_cancel_trackers", :force => true do |t|
    t.integer  "user_id"
    t.decimal  "amount",         :precision => 5, :scale => 1, :default => 0.0
    t.integer  "finance_id"
    t.string   "finance_type"
    t.date     "date"
    t.integer  "transaction_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "fine_cancel_trackers", ["school_id"], :name => "index_fine_cancel_trackers_on_school_id", :limit => {"school_id"=>nil}

  create_table "fine_rules", :force => true do |t|
    t.integer  "fine_id"
    t.integer  "fine_days"
    t.decimal  "fine_amount", :precision => 10, :scale => 4
    t.boolean  "is_amount"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "fine_rules", ["fine_id"], :name => "index_fine_rules_on_fine_id", :limit => {"fine_id"=>nil}
  add_index "fine_rules", ["school_id"], :name => "index_fine_rules_on_school_id", :limit => {"school_id"=>nil}

  create_table "fines", :force => true do |t|
    t.string   "name"
    t.boolean  "is_deleted", :default => false
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "fines", ["school_id"], :name => "index_fines_on_school_id", :limit => {"school_id"=>nil}

  create_table "folder_assignment_types", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "folder_assignment_types", ["school_id"], :name => "index_folder_assignment_types_on_school_id", :limit => {"school_id"=>nil}

  create_table "folders", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.string   "type"
    t.boolean  "is_favorite", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.boolean  "is_active",   :default => true
  end

  add_index "folders", ["school_id"], :name => "index_folders_on_school_id", :limit => {"school_id"=>nil}
  add_index "folders", ["type", "user_id"], :name => "index_folders_on_type_and_user_id", :limit => {"type"=>nil, "user_id"=>nil}

  create_table "form_field_options", :force => true do |t|
    t.text     "label"
    t.integer  "form_field_id"
    t.integer  "placement_order"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "weight"
    t.integer  "school_id"
  end

  add_index "form_field_options", ["form_field_id"], :name => "index_by_field_id", :limit => {"form_field_id"=>nil}

  create_table "form_fields", :force => true do |t|
    t.text     "label"
    t.integer  "form_template_id"
    t.string   "field_type"
    t.text     "field_settings"
    t.integer  "placement_order"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "form_fields", ["form_template_id"], :name => "index_by_template_id", :limit => {"form_template_id"=>nil}

  create_table "form_file_attachments", :force => true do |t|
    t.integer  "form_field_file_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.integer  "school_id"
  end

  add_index "form_file_attachments", ["form_field_file_id"], :name => "index_by_file_field_id", :limit => {"form_field_file_id"=>nil}

  create_table "form_submissions", :force => true do |t|
    t.integer  "form_id"
    t.text     "response"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "target"
    t.integer  "school_id"
    t.integer  "ward_id"
  end

  add_index "form_submissions", ["target", "ward_id", "form_id"], :name => "index_by_form_and_form_viewers", :limit => {"form_id"=>nil, "ward_id"=>nil, "target"=>nil}

  create_table "form_targets_users", :id => false, :force => true do |t|
    t.integer "form_id"
    t.integer "user_id"
  end

  add_index "form_targets_users", ["user_id", "form_id"], :name => "index_by_form_target_users", :limit => {"form_id"=>nil, "user_id"=>nil}

  create_table "form_templates", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_deleted", :default => false
    t.integer  "school_id"
  end

  add_index "form_templates", ["user_id"], :name => "index_by_users", :limit => {"user_id"=>nil}

  create_table "forms", :force => true do |t|
    t.integer  "form_template_id"
    t.string   "name"
    t.integer  "user_id"
    t.boolean  "is_public",           :default => true
    t.boolean  "is_closed",           :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_multi_submitable", :default => false
    t.boolean  "is_feedback",         :default => false
    t.integer  "is_parent",           :default => 1
    t.boolean  "is_editable",         :default => false
    t.boolean  "is_targeted"
    t.integer  "school_id"
  end

  add_index "forms", ["form_template_id", "is_closed", "is_public", "is_feedback", "is_targeted"], :name => "index_by_form_properties", :limit => {"form_template_id"=>nil, "is_targeted"=>nil, "is_closed"=>nil, "is_feedback"=>nil, "is_public"=>nil}

  create_table "forms_users", :id => false, :force => true do |t|
    t.integer "form_id"
    t.integer "user_id"
  end

  add_index "forms_users", ["user_id", "form_id"], :name => "index_by_fields", :limit => {"form_id"=>nil, "user_id"=>nil}

  create_table "formula_and_conditions", :force => true do |t|
    t.string   "expression1"
    t.string   "expression2"
    t.integer  "operation"
    t.string   "value"
    t.integer  "hr_formula_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "formula_and_conditions", ["hr_formula_id"], :name => "index_formula_and_conditions_on_hr_formula_id", :limit => {"hr_formula_id"=>nil}
  add_index "formula_and_conditions", ["school_id"], :name => "index_formula_and_conditions_on_school_id", :limit => {"school_id"=>nil}

  create_table "gallery_categories", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.boolean  "is_delete",      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.boolean  "visibility"
    t.boolean  "published",      :default => false
    t.date     "published_date"
    t.datetime "last_modified"
    t.boolean  "old_data",       :default => false
  end

  add_index "gallery_categories", ["school_id"], :name => "index_gallery_categories_on_school_id", :limit => {"school_id"=>nil}

  create_table "gallery_category_privileges", :force => true do |t|
    t.integer  "gallery_category_id"
    t.integer  "imageable_id"
    t.string   "imageable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "gallery_category_privileges", ["school_id"], :name => "index_gallery_category_privileges_on_school_id", :limit => {"school_id"=>nil}

  create_table "gallery_photos", :force => true do |t|
    t.integer  "gallery_category_id"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.string   "name"
    t.integer  "school_id"
    t.boolean  "old_data",            :default => false
    t.boolean  "is_deleted",          :default => false
  end

  add_index "gallery_photos", ["school_id"], :name => "index_gallery_photos_on_school_id", :limit => {"school_id"=>nil}

  create_table "gallery_tags", :force => true do |t|
    t.integer  "gallery_photo_id"
    t.integer  "member_id"
    t.string   "member_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "gallery_tags", ["school_id"], :name => "index_gallery_tags_on_school_id", :limit => {"school_id"=>nil}

  create_table "gateway_assignees", :force => true do |t|
    t.integer  "custom_gateway_id"
    t.integer  "assignee_id"
    t.string   "assignee_type"
    t.boolean  "is_owner",          :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "gateway_requests", :force => true do |t|
    t.string   "gateway"
    t.string   "transaction_reference", :limit => 36
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "status",                              :default => false
  end

  add_index "gateway_requests", ["transaction_reference", "status"], :name => "index_on_reference", :limit => {"transaction_reference"=>nil, "status"=>nil}

  create_table "generated_certificates", :force => true do |t|
    t.text     "certificate_html"
    t.integer  "issued_for_id"
    t.string   "issued_for_type"
    t.date     "issued_on"
    t.string   "manual_serial_no"
    t.integer  "serial_no",                     :limit => 8
    t.integer  "certificate_template_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "batch_id"
    t.integer  "bulk_generated_certificate_id"
  end

  add_index "generated_certificates", ["school_id"], :name => "index_generated_certificates_on_school_id", :limit => {"school_id"=>nil}

  create_table "generated_id_cards", :force => true do |t|
    t.text     "id_card_html_front"
    t.text     "id_card_html_back"
    t.integer  "issued_for_id"
    t.string   "issued_for_type"
    t.date     "issued_on"
    t.string   "serial_no"
    t.integer  "id_card_template_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "batch_id"
  end

  add_index "generated_id_cards", ["school_id"], :name => "index_generated_id_cards_on_school_id", :limit => {"school_id"=>nil}

  create_table "generated_pdfs", :force => true do |t|
    t.string   "pdf_file_name"
    t.string   "pdf_content_type"
    t.integer  "pdf_file_size"
    t.datetime "pdf_updated_at"
    t.integer  "corresponding_pdf_id"
    t.string   "corresponding_pdf_type"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "style"
  end

  add_index "generated_pdfs", ["school_id"], :name => "index_generated_pdfs_on_school_id", :limit => {"school_id"=>nil}

  create_table "generated_report_batches", :force => true do |t|
    t.integer  "generated_report_id"
    t.integer  "batch_id"
    t.integer  "generation_status",            :default => 1
    t.boolean  "report_published",             :default => false
    t.text     "last_error"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "batch_wise_student_report_id"
    t.datetime "published_date"
    t.integer  "school_id"
  end

  add_index "generated_report_batches", ["batch_id"], :name => "index_generated_report_batches_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "generated_report_batches", ["batch_wise_student_report_id"], :name => "index_on_report", :limit => {"batch_wise_student_report_id"=>nil}
  add_index "generated_report_batches", ["generated_report_id"], :name => "index_generated_report_batches_on_generated_report_id", :limit => {"generated_report_id"=>nil}
  add_index "generated_report_batches", ["generation_status"], :name => "index_generated_report_batches_on_generation_status", :limit => {"generation_status"=>nil}
  add_index "generated_report_batches", ["school_id"], :name => "index_generated_report_batches_on_school_id", :limit => {"school_id"=>nil}

  create_table "generated_reports", :force => true do |t|
    t.integer  "report_id"
    t.string   "report_type"
    t.integer  "course_id"
    t.boolean  "edited",      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "generated_reports", ["course_id"], :name => "index_generated_reports_on_course_id", :limit => {"course_id"=>nil}
  add_index "generated_reports", ["report_id", "report_type"], :name => "index_generated_reports_on_report_id_and_report_type", :limit => {"report_id"=>nil, "report_type"=>nil}
  add_index "generated_reports", ["school_id"], :name => "index_generated_reports_on_school_id", :limit => {"school_id"=>nil}

  create_table "grade_sets", :force => true do |t|
    t.string   "name"
    t.boolean  "direct_grade",         :default => true
    t.boolean  "enable_credit_points", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_default",           :default => false
    t.boolean  "description_enabled",  :default => false
    t.integer  "school_id"
  end

  add_index "grade_sets", ["direct_grade"], :name => "index_grade_sets_on_direct_grade", :limit => {"direct_grade"=>nil}
  add_index "grade_sets", ["school_id"], :name => "index_grade_sets_on_school_id", :limit => {"school_id"=>nil}

  create_table "gradebook_attendances", :force => true do |t|
    t.integer  "student_id"
    t.integer  "batch_id"
    t.string   "linkable_type"
    t.integer  "linkable_id"
    t.decimal  "total_working_days", :precision => 5, :scale => 1
    t.decimal  "total_days_present", :precision => 5, :scale => 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "report_type"
    t.integer  "school_id"
  end

  add_index "gradebook_attendances", ["school_id"], :name => "index_gradebook_attendances_on_school_id", :limit => {"school_id"=>nil}

  create_table "gradebook_record_groups", :force => true do |t|
    t.integer "assessment_plan_id"
    t.string  "name"
    t.integer "priority"
    t.integer "school_id"
  end

  add_index "gradebook_record_groups", ["school_id"], :name => "index_gradebook_record_groups_on_school_id", :limit => {"school_id"=>nil}

  create_table "gradebook_records", :force => true do |t|
    t.string   "linkable_type"
    t.integer  "linkable_id"
    t.integer  "record_group_id"
    t.integer  "gradebook_record_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "gradebook_records", ["gradebook_record_group_id"], :name => "index_by_gradebook_record_group_id", :limit => {"gradebook_record_group_id"=>nil}
  add_index "gradebook_records", ["school_id"], :name => "index_gradebook_records_on_school_id", :limit => {"school_id"=>nil}

  create_table "gradebook_remarks", :force => true do |t|
    t.integer "student_id"
    t.integer "batch_id"
    t.text    "remark_body",     :limit => 2147483647
    t.integer "reportable_id"
    t.string  "reportable_type"
    t.integer "remarkable_id"
    t.string  "remarkable_type"
    t.integer "school_id"
  end

  add_index "gradebook_remarks", ["student_id", "batch_id", "reportable_type", "reportable_id", "remarkable_type", "remarkable_id"], :name => "by_reportable_and_remarkable", :limit => {"batch_id"=>nil, "student_id"=>nil, "remarkable_id"=>nil, "reportable_type"=>nil, "remarkable_type"=>nil, "reportable_id"=>nil}

  create_table "gradebook_template_schools", :id => false, :force => true do |t|
    t.integer "gradebook_template_id"
    t.integer "school_id"
  end

  add_index "gradebook_template_schools", ["gradebook_template_id", "school_id"], :name => "index_on_tmpl_school", :limit => {"gradebook_template_id"=>nil, "school_id"=>nil}

  create_table "gradebook_templates", :force => true do |t|
    t.string   "name"
    t.text     "template"
    t.boolean  "is_default",    :default => false
    t.boolean  "is_active",     :default => true
    t.boolean  "is_common",     :default => true
    t.string   "file_checksum"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "grades", :force => true do |t|
    t.string   "name"
    t.integer  "grade_set_id"
    t.decimal  "minimum_marks", :precision => 10, :scale => 2
    t.decimal  "credit_points", :precision => 10, :scale => 2
    t.boolean  "pass_criteria",                                :default => true
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "grades", ["grade_set_id"], :name => "index_grades_on_grade_set_id", :limit => {"grade_set_id"=>nil}
  add_index "grades", ["school_id"], :name => "index_grades_on_school_id", :limit => {"school_id"=>nil}

  create_table "grading_levels", :force => true do |t|
    t.string   "name"
    t.integer  "batch_id"
    t.integer  "min_score"
    t.integer  "order"
    t.boolean  "is_deleted",                                   :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "credit_points", :precision => 15, :scale => 2
    t.string   "description"
    t.integer  "school_id"
  end

  add_index "grading_levels", ["batch_id", "is_deleted"], :name => "index_grading_levels_on_batch_id_and_is_deleted", :limit => {"is_deleted"=>nil, "batch_id"=>nil}
  add_index "grading_levels", ["school_id"], :name => "index_grading_levels_on_school_id", :limit => {"school_id"=>nil}

  create_table "grn_items", :force => true do |t|
    t.integer  "quantity"
    t.decimal  "unit_price",    :precision => 12, :scale => 4
    t.decimal  "tax",           :precision => 10, :scale => 4
    t.decimal  "discount",      :precision => 10, :scale => 4
    t.datetime "expiry_date"
    t.boolean  "is_deleted",                                   :default => false
    t.integer  "grn_id"
    t.integer  "store_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "grn_items", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "grns", :force => true do |t|
    t.string   "grn_no"
    t.string   "invoice_no"
    t.datetime "grn_date"
    t.datetime "invoice_date"
    t.decimal  "other_charges",          :precision => 10, :scale => 4
    t.boolean  "is_deleted",                                            :default => false
    t.integer  "purchase_order_id"
    t.integer  "finance_transaction_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.integer  "tax_mode",                                              :default => 1
    t.integer  "financial_year_id"
  end

  add_index "grns", ["financial_year_id"], :name => "index_by_fyid", :limit => {"financial_year_id"=>nil}
  add_index "grns", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "group_files", :force => true do |t|
    t.integer  "group_id"
    t.integer  "user_id"
    t.string   "file_description"
    t.integer  "group_post_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "doc_file_name"
    t.string   "doc_content_type"
    t.integer  "doc_file_size"
    t.datetime "doc_updated_at"
    t.integer  "school_id"
  end

  add_index "group_files", ["school_id"], :name => "index_group_files_on_school_id", :limit => {"school_id"=>nil}

  create_table "group_members", :force => true do |t|
    t.integer  "group_id"
    t.integer  "user_id"
    t.boolean  "is_admin",   :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "group_members", ["school_id"], :name => "index_group_members_on_school_id", :limit => {"school_id"=>nil}

  create_table "group_post_comments", :force => true do |t|
    t.integer  "group_post_id"
    t.integer  "user_id"
    t.text     "comment_body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "group_post_comments", ["school_id"], :name => "index_group_post_comments_on_school_id", :limit => {"school_id"=>nil}

  create_table "group_posts", :force => true do |t|
    t.integer  "group_id"
    t.integer  "user_id"
    t.string   "post_title"
    t.text     "post_body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "group_posts", ["school_id"], :name => "index_group_posts_on_school_id", :limit => {"school_id"=>nil}

  create_table "grouped_batches", :force => true do |t|
    t.integer  "batch_group_id"
    t.integer  "batch_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "grouped_batches", ["batch_group_id"], :name => "index_grouped_batches_on_batch_group_id", :limit => {"batch_group_id"=>nil}
  add_index "grouped_batches", ["school_id"], :name => "index_grouped_batches_on_school_id", :limit => {"school_id"=>nil}

  create_table "grouped_exam_reports", :force => true do |t|
    t.integer  "batch_id"
    t.integer  "student_id"
    t.integer  "exam_group_id"
    t.decimal  "marks",         :precision => 15, :scale => 2
    t.string   "score_type"
    t.integer  "subject_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "percentage",    :precision => 15, :scale => 4
    t.integer  "school_id"
  end

  add_index "grouped_exam_reports", ["batch_id", "student_id", "score_type"], :name => "by_batch_student_and_score_type", :limit => {"score_type"=>nil, "student_id"=>nil, "batch_id"=>nil}
  add_index "grouped_exam_reports", ["school_id"], :name => "index_grouped_exam_reports_on_school_id", :limit => {"school_id"=>nil}
  add_index "grouped_exam_reports", ["student_id", "score_type"], :name => "index_on_student_id_and_score_type", :limit => {"score_type"=>nil, "student_id"=>nil}

  create_table "grouped_exams", :force => true do |t|
    t.integer  "exam_group_id"
    t.integer  "batch_id"
    t.decimal  "weightage",     :precision => 15, :scale => 2
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "grouped_exams", ["batch_id", "exam_group_id"], :name => "index_grouped_exams_on_batch_id_and_exam_group_id", :limit => {"exam_group_id"=>nil, "batch_id"=>nil}
  add_index "grouped_exams", ["batch_id"], :name => "index_grouped_exams_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "grouped_exams", ["school_id"], :name => "index_grouped_exams_on_school_id", :limit => {"school_id"=>nil}

  create_table "groups", :force => true do |t|
    t.string   "group_name"
    t.text     "group_description"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.integer  "school_id"
  end

  add_index "groups", ["school_id"], :name => "index_groups_on_school_id", :limit => {"school_id"=>nil}

  create_table "guardians", :force => true do |t|
    t.integer  "ward_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "relation"
    t.string   "email"
    t.string   "office_phone1"
    t.string   "office_phone2"
    t.string   "mobile_phone"
    t.string   "office_address_line1"
    t.string   "office_address_line2"
    t.string   "city"
    t.string   "state"
    t.integer  "country_id"
    t.date     "dob"
    t.string   "occupation"
    t.string   "income"
    t.string   "education"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.integer  "familyid",             :limit => 8
    t.integer  "school_id"
  end

  add_index "guardians", ["familyid"], :name => "index_guardians_on_familyid", :limit => {"familyid"=>nil}
  add_index "guardians", ["first_name", "last_name", "relation"], :name => "ward_guardian_index", :limit => {"last_name"=>nil, "first_name"=>nil, "relation"=>nil}
  add_index "guardians", ["school_id"], :name => "index_guardians_on_school_id", :limit => {"school_id"=>nil}
  add_index "guardians", ["user_id"], :name => "index_guardians_on_user_id", :limit => {"user_id"=>nil}
  add_index "guardians", ["ward_id", "first_name", "last_name", "relation"], :name => "ward_guardian_unique_index", :unique => true, :limit => {"last_name"=>nil, "first_name"=>nil, "ward_id"=>nil, "relation"=>nil}

  create_table "hostel_additional_field_options", :force => true do |t|
    t.string   "field_option"
    t.integer  "hostel_additional_field_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hostel_fee_collections", :force => true do |t|
    t.string   "name"
    t.integer  "batch_id"
    t.date     "start_date"
    t.date     "end_date"
    t.date     "due_date"
    t.boolean  "is_deleted",               :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.boolean  "tax_enabled",              :default => false
    t.boolean  "invoice_enabled",          :default => false
    t.integer  "fee_account_id"
    t.integer  "financial_year_id"
    t.integer  "master_fee_particular_id"
  end

  add_index "hostel_fee_collections", ["batch_id"], :name => "index_hostel_fee_collections_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "hostel_fee_collections", ["due_date"], :name => "index_hostel_fee_collections_on_due_date", :limit => {"due_date"=>nil}
  add_index "hostel_fee_collections", ["financial_year_id"], :name => "by_financial_year_id", :limit => {"financial_year_id"=>nil}
  add_index "hostel_fee_collections", ["is_deleted", "due_date"], :name => "is_deleted_and_due_date", :limit => {"due_date"=>nil, "is_deleted"=>nil}
  add_index "hostel_fee_collections", ["is_deleted"], :name => "index_hostel_fee_collections_on_is_deleted", :limit => {"is_deleted"=>nil}
  add_index "hostel_fee_collections", ["master_fee_particular_id"], :name => "by_master_particular_id", :limit => {"master_fee_particular_id"=>nil}
  add_index "hostel_fee_collections", ["school_id"], :name => "index_hostel_fee_collections_on_school_id", :limit => {"school_id"=>nil}

  create_table "hostel_fee_finance_transactions", :force => true do |t|
    t.decimal  "transaction_balance",    :precision => 15, :scale => 4
    t.decimal  "transaction_amount",     :precision => 15, :scale => 4
    t.integer  "finance_transaction_id"
    t.integer  "parent_id"
    t.integer  "hostel_fee_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "hostel_fee_finance_transactions", ["finance_transaction_id"], :name => "index_hostel_fee_finance_transactions_on_finance_transaction_id", :limit => {"finance_transaction_id"=>nil}

  create_table "hostel_fees", :force => true do |t|
    t.integer  "student_id"
    t.integer  "finance_transaction_id"
    t.integer  "hostel_fee_collection_id"
    t.decimal  "rent",                     :precision => 15, :scale => 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.boolean  "is_active",                                               :default => true
    t.integer  "batch_id"
    t.decimal  "balance",                  :precision => 15, :scale => 4
    t.decimal  "tax_amount",               :precision => 15, :scale => 4
    t.boolean  "tax_enabled",                                             :default => false
  end

  add_index "hostel_fees", ["batch_id"], :name => "index_hostel_fees_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "hostel_fees", ["hostel_fee_collection_id"], :name => "index_hostel_fees_on_hostel_fee_collection_id", :limit => {"hostel_fee_collection_id"=>nil}
  add_index "hostel_fees", ["rent"], :name => "index_hostel_fees_on_rent", :limit => {"rent"=>nil}
  add_index "hostel_fees", ["school_id"], :name => "index_hostel_fees_on_school_id", :limit => {"school_id"=>nil}
  add_index "hostel_fees", ["student_id", "finance_transaction_id"], :name => "index_on_finance_transactions", :limit => {"finance_transaction_id"=>nil, "student_id"=>nil}

  create_table "hostel_room_additional_details", :force => true do |t|
    t.integer  "linkable_id"
    t.string   "linkable_type"
    t.integer  "hostel_room_additional_field_id"
    t.string   "additional_info"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hostel_room_additional_fields", :force => true do |t|
    t.string   "name"
    t.boolean  "is_mandatory"
    t.string   "input_type"
    t.integer  "priority"
    t.boolean  "is_active"
    t.integer  "school_id"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hostels", :force => true do |t|
    t.string   "name"
    t.string   "hostel_type"
    t.string   "other_info"
    t.integer  "employee_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "hostels", ["school_id"], :name => "index_hostels_on_school_id", :limit => {"school_id"=>nil}

  create_table "hr_formulas", :force => true do |t|
    t.integer  "value_type"
    t.string   "default_value"
    t.integer  "formula_id"
    t.string   "formula_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "hr_formulas", ["formula_id", "formula_type"], :name => "index_hr_formulas_on_formula_id_and_formula_type", :limit => {"formula_id"=>nil, "formula_type"=>nil}
  add_index "hr_formulas", ["school_id"], :name => "index_hr_formulas_on_school_id", :limit => {"school_id"=>nil}

  create_table "hr_reports", :force => true do |t|
    t.string   "report_name"
    t.string   "name"
    t.text     "report_columns"
    t.text     "report_filters"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "hr_reports", ["school_id"], :name => "index_hr_reports_on_school_id", :limit => {"school_id"=>nil}

  create_table "hr_seed_errors_logs", :force => true do |t|
    t.string   "model_name"
    t.text     "data_rows"
    t.text     "error_messages"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "hr_seed_errors_logs", ["school_id"], :name => "index_hr_seed_errors_logs_on_school_id", :limit => {"school_id"=>nil}

  create_table "ia_calculations", :force => true do |t|
    t.string   "formula"
    t.integer  "ia_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "ia_calculations", ["ia_group_id"], :name => "index_ia_calculations_on_ia_group_id", :limit => {"ia_group_id"=>nil}
  add_index "ia_calculations", ["school_id"], :name => "index_ia_calculations_on_school_id", :limit => {"school_id"=>nil}

  create_table "ia_groups", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "icse_exam_category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "ia_groups", ["school_id"], :name => "index_ia_groups_on_school_id", :limit => {"school_id"=>nil}

  create_table "ia_groups_subjects", :id => false, :force => true do |t|
    t.integer "ia_group_id"
    t.integer "subject_id"
  end

  add_index "ia_groups_subjects", ["ia_group_id", "subject_id"], :name => "index_by_fields", :limit => {"ia_group_id"=>nil, "subject_id"=>nil}

  create_table "ia_indicators", :force => true do |t|
    t.string   "name"
    t.decimal  "max_mark",    :precision => 15, :scale => 2
    t.string   "indicator"
    t.integer  "ia_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "ia_indicators", ["ia_group_id"], :name => "index_ia_indicators_on_ia_group_id", :limit => {"ia_group_id"=>nil}
  add_index "ia_indicators", ["school_id"], :name => "index_ia_indicators_on_school_id", :limit => {"school_id"=>nil}

  create_table "ia_scores", :force => true do |t|
    t.decimal  "mark",            :precision => 15, :scale => 2
    t.integer  "student_id"
    t.integer  "exam_id"
    t.integer  "batch_id"
    t.integer  "ia_indicator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "ia_scores", ["exam_id"], :name => "index_ia_scores_on_exam_id", :limit => {"exam_id"=>nil}
  add_index "ia_scores", ["ia_indicator_id"], :name => "index_ia_scores_on_ia_indicator_id", :limit => {"ia_indicator_id"=>nil}
  add_index "ia_scores", ["school_id"], :name => "index_ia_scores_on_school_id", :limit => {"school_id"=>nil}

  create_table "icse_exam_categories", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_detailed_report", :default => true
    t.integer  "school_id"
  end

  add_index "icse_exam_categories", ["school_id"], :name => "index_icse_exam_categories_on_school_id", :limit => {"school_id"=>nil}

  create_table "icse_report_setting_copies", :force => true do |t|
    t.integer  "batch_id"
    t.string   "setting_key"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "icse_report_setting_copies", ["school_id"], :name => "index_icse_report_setting_copies_on_school_id", :limit => {"school_id"=>nil}

  create_table "icse_report_settings", :force => true do |t|
    t.string   "setting_key"
    t.string   "setting_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "icse_report_settings", ["school_id"], :name => "index_icse_report_settings_on_school_id", :limit => {"school_id"=>nil}

  create_table "icse_reports", :force => true do |t|
    t.integer  "batch_id"
    t.integer  "exam_id"
    t.integer  "student_id"
    t.decimal  "ia_score",    :precision => 15, :scale => 2
    t.decimal  "ea_score",    :precision => 15, :scale => 2
    t.decimal  "ia_mark",     :precision => 15, :scale => 2
    t.decimal  "ea_mark",     :precision => 15, :scale => 2
    t.decimal  "total_score", :precision => 15, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "icse_reports", ["exam_id"], :name => "index_icse_reports_on_exam_id", :limit => {"exam_id"=>nil}
  add_index "icse_reports", ["school_id"], :name => "index_icse_reports_on_school_id", :limit => {"school_id"=>nil}

  create_table "icse_weightages", :force => true do |t|
    t.string   "name"
    t.integer  "icse_exam_category_id"
    t.decimal  "ea_weightage",          :precision => 15, :scale => 2
    t.decimal  "ia_weightage",          :precision => 15, :scale => 2
    t.boolean  "is_grade",                                             :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_co_curricular",                                     :default => false
    t.string   "grade_type"
    t.integer  "school_id"
  end

  add_index "icse_weightages", ["school_id"], :name => "index_icse_weightages_on_school_id", :limit => {"school_id"=>nil}

  create_table "icse_weightages_subjects", :id => false, :force => true do |t|
    t.integer "icse_weightage_id"
    t.integer "subject_id"
  end

  add_index "icse_weightages_subjects", ["icse_weightage_id", "subject_id"], :name => "index_by_fields", :limit => {"icse_weightage_id"=>nil, "subject_id"=>nil}

  create_table "id_card_templates", :force => true do |t|
    t.string   "name"
    t.integer  "user_type"
    t.string   "serial_no"
    t.integer  "top_padding"
    t.integer  "right_padding"
    t.integer  "left_padding"
    t.integer  "bottom_padding"
    t.string   "front_background_image_file_name"
    t.string   "front_background_image_content_type"
    t.integer  "front_background_image_file_size"
    t.datetime "front_background_image_updated_at"
    t.string   "include_back"
    t.string   "back_background_image_file_name"
    t.string   "back_background_image_content_type"
    t.integer  "back_background_image_file_size"
    t.datetime "back_background_image_updated_at"
    t.integer  "template_resolutions_id"
    t.integer  "front_template_id"
    t.integer  "back_template_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "id_card_templates", ["school_id"], :name => "index_id_card_templates_on_school_id", :limit => {"school_id"=>nil}

  create_table "import_log_details", :force => true do |t|
    t.integer  "import_id"
    t.string   "model"
    t.string   "status"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "import_log_details", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "imports", :force => true do |t|
    t.integer  "export_id"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.string   "csv_file_file_name"
    t.string   "csv_file_content_type"
    t.integer  "csv_file_file_size"
    t.datetime "csv_file_updated_at"
    t.boolean  "is_edit",               :default => false
    t.integer  "job_count",             :default => 0
  end

  add_index "imports", ["export_id"], :name => "index_imports_on_export_id", :limit => {"export_id"=>nil}
  add_index "imports", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "indent_items", :force => true do |t|
    t.integer  "quantity"
    t.string   "batch_no"
    t.integer  "pending"
    t.integer  "issued"
    t.string   "issued_type"
    t.decimal  "price",         :precision => 12, :scale => 4
    t.integer  "required"
    t.boolean  "is_deleted",                                   :default => false
    t.integer  "indent_id"
    t.integer  "store_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "indent_items", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "indents", :force => true do |t|
    t.string   "indent_no"
    t.datetime "expected_date"
    t.string   "status"
    t.boolean  "is_deleted",    :default => false
    t.text     "description"
    t.integer  "user_id"
    t.integer  "store_id"
    t.integer  "manager_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "indents", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "individual_payslip_categories", :force => true do |t|
    t.integer  "employee_id"
    t.date     "salary_date"
    t.string   "name"
    t.string   "amount"
    t.boolean  "is_deduction"
    t.boolean  "include_every_month"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "employee_payslip_id"
    t.integer  "school_id"
  end

  add_index "individual_payslip_categories", ["employee_id"], :name => "index_individual_payslip_categories_on_employee_id", :limit => {"employee_id"=>nil}
  add_index "individual_payslip_categories", ["employee_payslip_id"], :name => "index_individual_payslip_categories_on_employee_payslip_id", :limit => {"employee_payslip_id"=>nil}
  add_index "individual_payslip_categories", ["school_id"], :name => "index_individual_payslip_categories_on_school_id", :limit => {"school_id"=>nil}

  create_table "individual_report_pdfs", :force => true do |t|
    t.integer  "individual_report_id"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.string   "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "individual_report_pdfs", ["school_id"], :name => "index_individual_report_pdfs_on_school_id", :limit => {"school_id"=>nil}

  create_table "individual_reports", :force => true do |t|
    t.integer  "reportable_id"
    t.string   "reportable_type"
    t.integer  "student_id"
    t.integer  "generated_report_batch_id"
    t.text     "report"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "report_component",          :limit => 2147483647
    t.integer  "school_id"
  end

  add_index "individual_reports", ["generated_report_batch_id"], :name => "index_individual_reports_on_generated_report_batch_id", :limit => {"generated_report_batch_id"=>nil}
  add_index "individual_reports", ["reportable_id", "reportable_type"], :name => "index_individual_reports_on_reportable_id_and_reportable_type", :limit => {"reportable_type"=>nil, "reportable_id"=>nil}
  add_index "individual_reports", ["school_id"], :name => "index_individual_reports_on_school_id", :limit => {"school_id"=>nil}
  add_index "individual_reports", ["student_id"], :name => "index_individual_reports_on_student_id", :limit => {"student_id"=>nil}

  create_table "instant_fee_categories", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.boolean  "is_deleted",        :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.integer  "financial_year_id"
  end

  add_index "instant_fee_categories", ["financial_year_id"], :name => "index_instant_fee_categories_on_financial_year_id", :limit => {"financial_year_id"=>nil}
  add_index "instant_fee_categories", ["school_id"], :name => "index_instant_fee_categories_on_school_id", :limit => {"school_id"=>nil}

  create_table "instant_fee_details", :force => true do |t|
    t.integer  "instant_fee_id"
    t.integer  "instant_fee_particular_id"
    t.string   "custom_particular"
    t.decimal  "amount",                    :precision => 15, :scale => 4
    t.decimal  "discount",                  :precision => 15, :scale => 4
    t.decimal  "net_amount",                :precision => 15, :scale => 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.decimal  "tax",                       :precision => 15, :scale => 4
    t.decimal  "tax_amount",                :precision => 15, :scale => 4
    t.integer  "slab_id"
    t.integer  "master_fee_discount_id"
    t.integer  "master_fee_particular_id"
    t.boolean  "is_active",                                                :default => true
  end

  add_index "instant_fee_details", ["is_active"], :name => "index_by_is_active", :limit => {"is_active"=>nil}
  add_index "instant_fee_details", ["master_fee_discount_id"], :name => "index_by_mfd_id", :limit => {"master_fee_discount_id"=>nil}
  add_index "instant_fee_details", ["master_fee_particular_id"], :name => "index_by_mfp_id", :limit => {"master_fee_particular_id"=>nil}
  add_index "instant_fee_details", ["school_id"], :name => "index_instant_fee_details_on_school_id", :limit => {"school_id"=>nil}

  create_table "instant_fee_particulars", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.decimal  "amount",                   :precision => 15, :scale => 4
    t.integer  "instant_fee_category_id"
    t.boolean  "is_deleted",                                              :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.integer  "master_fee_particular_id"
  end

  add_index "instant_fee_particulars", ["master_fee_particular_id"], :name => "index_by_mfd_id", :limit => {"master_fee_particular_id"=>nil}
  add_index "instant_fee_particulars", ["school_id"], :name => "index_instant_fee_particulars_on_school_id", :limit => {"school_id"=>nil}

  create_table "instant_fees", :force => true do |t|
    t.integer  "instant_fee_category_id"
    t.string   "custom_category"
    t.integer  "payee_id"
    t.string   "payee_type"
    t.string   "guest_payee"
    t.decimal  "amount",                  :precision => 15, :scale => 4
    t.datetime "pay_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.text     "custom_description"
    t.string   "groupable_type"
    t.integer  "groupable_id"
    t.boolean  "tax_enabled",                                            :default => false
    t.decimal  "tax_amount",              :precision => 15, :scale => 4
    t.integer  "financial_year_id"
  end

  add_index "instant_fees", ["financial_year_id"], :name => "index_instant_fees_on_financial_year_id", :limit => {"financial_year_id"=>nil}
  add_index "instant_fees", ["groupable_id", "groupable_type"], :name => "index_instant_fees_on_groupable_id_and_groupable_type", :limit => {"groupable_id"=>nil, "groupable_type"=>nil}
  add_index "instant_fees", ["instant_fee_category_id"], :name => "index_instant_fees_on_instant_fee_category_id", :limit => {"instant_fee_category_id"=>nil}
  add_index "instant_fees", ["payee_id", "payee_type"], :name => "index_instant_fees_on_payee_id_and_payee_type", :limit => {"payee_type"=>nil, "payee_id"=>nil}
  add_index "instant_fees", ["school_id"], :name => "index_instant_fees_on_school_id", :limit => {"school_id"=>nil}

  create_table "invoices", :force => true do |t|
    t.string   "invoice_no"
    t.date     "date"
    t.decimal  "tax",               :precision => 15, :scale => 2
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.boolean  "is_paid",                                          :default => false
    t.integer  "tax_mode",                                         :default => 1
    t.integer  "financial_year_id"
  end

  add_index "invoices", ["financial_year_id"], :name => "index_by_fyid", :limit => {"financial_year_id"=>nil}
  add_index "invoices", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "item_categories", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.boolean  "is_deleted", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "item_categories", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "job_resource_locators", :force => true do |t|
    t.integer  "job_id"
    t.string   "context"
    t.string   "locator"
    t.integer  "status"
    t.string   "last_message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "job_resource_locators", ["school_id"], :name => "index_job_resource_locators_on_school_id", :limit => {"school_id"=>nil}

  create_table "leave_auto_credit_records", :force => true do |t|
    t.integer  "leave_type_id"
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "action"
    t.integer  "school_id"
  end

  add_index "leave_auto_credit_records", ["school_id"], :name => "index_leave_auto_credit_records_on_school_id", :limit => {"school_id"=>nil}

  create_table "leave_credit_logs", :force => true do |t|
    t.integer  "leave_credit_id"
    t.integer  "employee_id"
    t.integer  "status"
    t.integer  "retry_status"
    t.string   "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "leave_credit_logs", ["school_id"], :name => "index_leave_credit_logs_on_school_id", :limit => {"school_id"=>nil}

  create_table "leave_credit_slabs", :force => true do |t|
    t.integer  "employee_leave_type_id"
    t.string   "leave_label"
    t.string   "leave_count"
    t.integer  "label_order"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "leave_credits", :force => true do |t|
    t.integer  "leave_year_id"
    t.datetime "credited_date"
    t.integer  "credit_value"
    t.string   "remarks"
    t.boolean  "is_automatic"
    t.integer  "credited_by"
    t.integer  "status"
    t.integer  "employee_count"
    t.text     "leave_type_ids"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "credit_type"
    t.integer  "school_id"
  end

  add_index "leave_credits", ["school_id"], :name => "index_leave_credits_on_school_id", :limit => {"school_id"=>nil}

  create_table "leave_group_employees", :force => true do |t|
    t.integer  "leave_group_id"
    t.integer  "employee_id"
    t.string   "employee_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "leave_group_employees", ["employee_id"], :name => "index_leave_group_employees_on_employee_id", :limit => {"employee_id"=>nil}
  add_index "leave_group_employees", ["leave_group_id"], :name => "index_leave_group_employees_on_leave_group_id", :limit => {"leave_group_id"=>nil}
  add_index "leave_group_employees", ["school_id"], :name => "index_leave_group_employees_on_school_id", :limit => {"school_id"=>nil}

  create_table "leave_group_leave_types", :force => true do |t|
    t.integer  "leave_group_id"
    t.integer  "employee_leave_type_id"
    t.decimal  "leave_count",            :precision => 7, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "leave_group_leave_types", ["employee_leave_type_id"], :name => "index_leave_group_leave_types_on_employee_leave_type_id", :limit => {"employee_leave_type_id"=>nil}
  add_index "leave_group_leave_types", ["leave_group_id"], :name => "index_leave_group_leave_types_on_leave_group_id", :limit => {"leave_group_id"=>nil}
  add_index "leave_group_leave_types", ["school_id"], :name => "index_leave_group_leave_types_on_school_id", :limit => {"school_id"=>nil}

  create_table "leave_groups", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "updating_status"
    t.integer  "school_id"
  end

  add_index "leave_groups", ["school_id"], :name => "index_leave_groups_on_school_id", :limit => {"school_id"=>nil}

  create_table "leave_reset_logs", :force => true do |t|
    t.integer  "leave_reset_id"
    t.integer  "employee_id"
    t.integer  "status"
    t.boolean  "retry_status",   :default => false
    t.text     "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "leave_year_id"
    t.integer  "school_id"
  end

  add_index "leave_reset_logs", ["employee_id"], :name => "index_leave_reset_logs_on_employee_id", :limit => {"employee_id"=>nil}
  add_index "leave_reset_logs", ["leave_reset_id"], :name => "index_leave_reset_logs_on_leave_reset_id", :limit => {"leave_reset_id"=>nil}
  add_index "leave_reset_logs", ["school_id"], :name => "index_leave_reset_logs_on_school_id", :limit => {"school_id"=>nil}

  create_table "leave_resets", :force => true do |t|
    t.date     "reset_date"
    t.integer  "reset_type"
    t.string   "reset_remark"
    t.integer  "resetted_by"
    t.integer  "status"
    t.integer  "reset_value"
    t.integer  "employee_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "leave_type_ids"
    t.integer  "leave_year_id"
    t.integer  "school_id"
  end

  add_index "leave_resets", ["school_id"], :name => "index_leave_resets_on_school_id", :limit => {"school_id"=>nil}

  create_table "leave_years", :force => true do |t|
    t.string   "name"
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "is_active",  :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "leave_years", ["school_id"], :name => "index_leave_years_on_school_id", :limit => {"school_id"=>nil}

  create_table "liabilities", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.decimal  "amount",      :precision => 15, :scale => 4
    t.boolean  "is_solved",                                  :default => false
    t.boolean  "is_deleted",                                 :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "liabilities", ["school_id"], :name => "index_liabilities_on_school_id", :limit => {"school_id"=>nil}

  create_table "library_card_settings", :force => true do |t|
    t.integer  "course_id"
    t.integer  "student_category_id"
    t.integer  "books_issueable"
    t.integer  "time_period",         :default => 30
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "library_card_settings", ["school_id"], :name => "index_library_card_settings_on_school_id", :limit => {"school_id"=>nil}

  create_table "lop_prorated_formulas", :force => true do |t|
    t.integer  "employee_lop_id"
    t.integer  "payroll_category_id"
    t.boolean  "actual_value",         :default => false
    t.text     "dependant_categories"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "lop_prorated_formulas", ["school_id"], :name => "index_lop_prorated_formulas_on_school_id", :limit => {"school_id"=>nil}

  create_table "mail_attachments", :force => true do |t|
    t.integer  "mail_message_id"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mail_attachments", ["mail_message_id"], :name => "index_mail_attachments_on_mail_message_id", :limit => {"mail_message_id"=>nil}

  create_table "mail_log_recipient_lists", :force => true do |t|
    t.text     "recipients"
    t.integer  "mail_log_id"
    t.integer  "recipients_count", :default => 0
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mail_log_recipient_lists", ["mail_log_id"], :name => "index_mail_log_recipient_lists_on_mail_log_id", :limit => {"mail_log_id"=>nil}

  create_table "mail_logs", :force => true do |t|
    t.string   "subject"
    t.text     "body"
    t.string   "type"
    t.integer  "mail_message_id"
    t.string   "sender_mail_id"
    t.integer  "sender_id"
    t.string   "alert_record_type"
    t.integer  "alert_record_id"
    t.string   "alert_event"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mail_logs", ["school_id", "type"], :name => "index_mail_logs_on_school_id_and_type", :limit => {"type"=>nil, "school_id"=>nil}

  create_table "mail_messages", :force => true do |t|
    t.string   "subject"
    t.text     "body"
    t.integer  "sender_id"
    t.boolean  "has_template",    :default => false
    t.text     "additional_info"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mail_messages", ["school_id"], :name => "index_mail_messages_on_school_id", :limit => {"school_id"=>nil}

  create_table "mail_recipient_lists", :force => true do |t|
    t.integer  "mail_message_id"
    t.string   "recipient_type"
    t.text     "recipient_ids"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mail_recipient_lists", ["mail_message_id"], :name => "index_mail_recipient_lists_on_mail_message_id", :limit => {"mail_message_id"=>nil}

  create_table "marked_attendance_records", :force => true do |t|
    t.integer  "subject_id"
    t.date     "month_date"
    t.date     "saved_date"
    t.integer  "saved_by"
    t.date     "locked_date"
    t.integer  "locked_by"
    t.boolean  "is_locked"
    t.string   "attendance_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "batch_id"
    t.integer  "class_timing_id"
    t.integer  "academic_year_id"
    t.integer  "school_id"
  end

  add_index "marked_attendance_records", ["attendance_type"], :name => "index_by_attendance_type", :limit => {"attendance_type"=>nil}
  add_index "marked_attendance_records", ["school_id"], :name => "index_marked_attendance_records_on_school_id", :limit => {"school_id"=>nil}

  create_table "master_discount_reports", :force => true do |t|
    t.date     "date"
    t.integer  "master_fee_discount_id",                                                 :null => false
    t.integer  "student_id",                                                             :null => false
    t.integer  "batch_id",                                                               :null => false
    t.decimal  "amount",                 :precision => 15, :scale => 4, :default => 0.0
    t.integer  "school_id",                                                              :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "collection_type",                                                        :null => false
    t.integer  "collection_id",                                                          :null => false
    t.string   "digest",                                                                 :null => false
  end

  add_index "master_discount_reports", ["digest"], :name => "index_master_discount_reports_on_digest", :unique => true, :limit => {"digest"=>nil}
  add_index "master_discount_reports", ["school_id"], :name => "index_master_discount_reports_on_school_id", :limit => {"school_id"=>nil}

  create_table "master_fee_discounts", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "discount_type"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "master_fee_discounts", ["school_id"], :name => "index_master_fee_discounts_on_school_id", :limit => {"school_id"=>nil}

  create_table "master_fee_particulars", :force => true do |t|
    t.string   "name",            :null => false
    t.string   "description"
    t.string   "particular_type", :null => false
    t.integer  "school_id",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "master_fee_particulars", ["school_id"], :name => "index_master_fee_particulars_on_school_id", :limit => {"school_id"=>nil}

  create_table "master_particular_reports", :force => true do |t|
    t.date     "date"
    t.integer  "master_fee_particular_id",                                                 :null => false
    t.integer  "fee_account_id"
    t.integer  "student_id",                                                               :null => false
    t.integer  "batch_id",                                                                 :null => false
    t.string   "mode_of_payment",                                                          :null => false
    t.decimal  "amount",                   :precision => 15, :scale => 4, :default => 0.0
    t.integer  "school_id",                                                                :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "tax_amount",               :precision => 15, :scale => 4, :default => 0.0
    t.decimal  "discount_amount",          :precision => 15, :scale => 4, :default => 0.0
    t.string   "digest",                                                                   :null => false
    t.string   "collection_type",                                                          :null => false
    t.integer  "collection_id",                                                            :null => false
  end

  add_index "master_particular_reports", ["batch_id", "date"], :name => "index_by_batch_id_and_date", :limit => {"date"=>nil, "batch_id"=>nil}
  add_index "master_particular_reports", ["digest", "student_id", "collection_id", "collection_type"], :name => "compound_index_on_digest_student_id_colllection", :unique => true, :limit => {"student_id"=>nil, "digest"=>nil, "collection_type"=>nil, "collection_id"=>nil}
  add_index "master_particular_reports", ["school_id"], :name => "index_master_particular_reports_on_school_id", :limit => {"school_id"=>nil}
  add_index "master_particular_reports", ["student_id"], :name => "by_student_id", :limit => {"student_id"=>nil}

  create_table "menu_link_categories", :force => true do |t|
    t.string   "name"
    t.text     "allowed_roles"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "origin_name"
  end

  create_table "menu_links", :force => true do |t|
    t.string   "name"
    t.string   "target_controller"
    t.string   "target_action"
    t.integer  "higher_link_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "icon_class"
    t.string   "link_type"
    t.string   "user_type"
    t.integer  "menu_link_category_id"
  end

  create_table "message_attachments", :force => true do |t|
    t.integer  "message_id"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "message_attachments", ["message_id"], :name => "index_attachments", :limit => {"message_id"=>nil}
  add_index "message_attachments", ["school_id"], :name => "index_message_attachments_on_school_id", :limit => {"school_id"=>nil}

  create_table "message_attachments_assocs", :force => true do |t|
    t.integer "message_id"
    t.integer "message_attachment_id"
    t.integer "school_id"
  end

  add_index "message_attachments_assocs", ["school_id"], :name => "index_message_attachments_assocs_on_school_id", :limit => {"school_id"=>nil}

  create_table "message_recipients", :force => true do |t|
    t.integer  "message_id"
    t.integer  "recipient_id"
    t.integer  "thread_id"
    t.boolean  "is_read",      :default => false
    t.boolean  "is_deleted",   :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "message_recipients", ["message_id"], :name => "index_on_recipients", :limit => {"message_id"=>nil}
  add_index "message_recipients", ["recipient_id", "is_deleted", "is_read"], :name => "index_on_recipient_id__and_is_deleted_and_is_read", :limit => {"is_deleted"=>nil, "recipient_id"=>nil, "is_read"=>nil}
  add_index "message_recipients", ["school_id"], :name => "index_message_recipients_on_school_id", :limit => {"school_id"=>nil}

  create_table "message_settings", :force => true do |t|
    t.string   "config_key"
    t.string   "config_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "message_settings", ["school_id"], :name => "index_message_settings_on_school_id", :limit => {"school_id"=>nil}

  create_table "message_template_contents", :force => true do |t|
    t.text     "content"
    t.string   "user_type"
    t.integer  "message_template_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "message_template_contents", ["school_id"], :name => "index_message_template_contents_on_school_id", :limit => {"school_id"=>nil}
  add_index "message_template_contents", ["user_type"], :name => "index_by_user_type", :limit => {"user_type"=>nil}

  create_table "message_templates", :force => true do |t|
    t.string   "template_name"
    t.string   "template_type"
    t.string   "automated_template_name"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "message_templates", ["school_id"], :name => "index_message_templates_on_school_id", :limit => {"school_id"=>nil}

  create_table "message_threads", :force => true do |t|
    t.text     "subject"
    t.integer  "creator_id"
    t.boolean  "can_reply",        :default => true
    t.boolean  "is_deleted",       :default => false
    t.boolean  "is_group_message", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "message_threads", ["school_id"], :name => "index_message_threads_on_school_id", :limit => {"school_id"=>nil}

  create_table "messages", :force => true do |t|
    t.text     "body"
    t.integer  "sender_id"
    t.integer  "message_thread_id"
    t.boolean  "is_deleted",        :default => false
    t.boolean  "is_primary",        :default => false
    t.boolean  "is_to_all",         :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "messages", ["message_thread_id"], :name => "index_on_message_id", :limit => {"message_thread_id"=>nil}
  add_index "messages", ["school_id"], :name => "index_messages_on_school_id", :limit => {"school_id"=>nil}

  create_table "monthly_payslips", :force => true do |t|
    t.date     "salary_date"
    t.integer  "employee_id"
    t.integer  "payroll_category_id"
    t.string   "amount"
    t.boolean  "is_approved",            :default => false, :null => false
    t.integer  "approver_id"
    t.boolean  "is_rejected",            :default => false, :null => false
    t.integer  "rejector_id"
    t.string   "reason"
    t.string   "remark"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "finance_transaction_id"
    t.integer  "school_id"
  end

  add_index "monthly_payslips", ["school_id"], :name => "index_monthly_payslips_on_school_id", :limit => {"school_id"=>nil}

  create_table "multi_fee_discounts", :force => true do |t|
    t.integer  "receiver_id",                                                             :null => false
    t.string   "receiver_type",                                                           :null => false
    t.decimal  "discount",              :precision => 15, :scale => 4,                    :null => false
    t.boolean  "is_amount",                                            :default => false
    t.string   "name",                                                                    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "master_receiver_type",                                                    :null => false
    t.integer  "master_receiver_id",                                                      :null => false
    t.string   "fee_type"
    t.integer  "fee_id"
    t.decimal  "total_discount",        :precision => 15, :scale => 4
    t.integer  "transaction_ledger_id"
    t.integer  "school_id"
  end

  add_index "multi_fee_discounts", ["fee_type", "fee_id"], :name => "by_fee", :limit => {"fee_type"=>nil, "fee_id"=>nil}
  add_index "multi_fee_discounts", ["master_receiver_type", "master_receiver_id"], :name => "by_master_receiver", :limit => {"master_receiver_type"=>nil, "master_receiver_id"=>nil}
  add_index "multi_fee_discounts", ["receiver_type", "receiver_id"], :name => "index_by_receiver", :limit => {"receiver_id"=>nil, "receiver_type"=>nil}
  add_index "multi_fee_discounts", ["school_id"], :name => "index_multi_fee_discounts_on_school_id", :limit => {"school_id"=>nil}
  add_index "multi_fee_discounts", ["transaction_ledger_id"], :name => "index_on_transaction_ledger_id", :limit => {"transaction_ledger_id"=>nil}

  create_table "multi_fees_transactions", :force => true do |t|
    t.decimal  "amount",           :precision => 15, :scale => 2
    t.string   "payment_mode"
    t.text     "payment_note"
    t.date     "transaction_date"
    t.integer  "student_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "reference_no"
    t.integer  "school_id"
  end

  add_index "multi_fees_transactions", ["school_id"], :name => "index_multi_fees_transactions_on_school_id", :limit => {"school_id"=>nil}

  create_table "multi_fees_transactions_finance_transactions", :id => false, :force => true do |t|
    t.integer "multi_fees_transaction_id"
    t.integer "finance_transaction_id"
  end

  add_index "multi_fees_transactions_finance_transactions", ["finance_transaction_id"], :name => "index_on_finance_transaction_id", :limit => {"finance_transaction_id"=>nil}
  add_index "multi_fees_transactions_finance_transactions", ["multi_fees_transaction_id"], :name => "index_on_multi_fees_transaction_id", :limit => {"multi_fees_transaction_id"=>nil}

  create_table "multi_transaction_fines", :force => true do |t|
    t.string   "name"
    t.decimal  "amount",        :precision => 15, :scale => 4, :null => false
    t.integer  "receiver_id",                                  :null => false
    t.string   "receiver_type",                                :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "multi_transaction_fines", ["receiver_type", "receiver_id"], :name => "index_by_receiver", :limit => {"receiver_id"=>nil, "receiver_type"=>nil}
  add_index "multi_transaction_fines", ["school_id"], :name => "index_multi_transaction_fines_on_school_id", :limit => {"school_id"=>nil}

  create_table "news", :force => true do |t|
    t.string   "title"
    t.text     "content"
    t.integer  "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "news", ["school_id"], :name => "index_news_on_school_id", :limit => {"school_id"=>nil}

  create_table "news_attachments", :force => true do |t|
    t.integer  "news_id"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "news_attachments", ["news_id"], :name => "index_news_attachments_on_news_id", :limit => {"news_id"=>nil}
  add_index "news_attachments", ["school_id"], :name => "index_news_attachments_on_school_id", :limit => {"school_id"=>nil}

  create_table "news_comments", :force => true do |t|
    t.text     "content"
    t.integer  "news_id"
    t.integer  "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_approved", :default => false
    t.integer  "school_id"
  end

  add_index "news_comments", ["school_id"], :name => "index_news_comments_on_school_id", :limit => {"school_id"=>nil}

  create_table "notification_recipients", :force => true do |t|
    t.integer "notification_id"
    t.integer "recipient_id"
    t.boolean "is_read",         :default => false
    t.integer "school_id"
  end

  add_index "notification_recipients", ["notification_id"], :name => "index_notification", :limit => {"notification_id"=>nil}
  add_index "notification_recipients", ["notification_id"], :name => "index_on_notification_id", :limit => {"notification_id"=>nil}
  add_index "notification_recipients", ["recipient_id"], :name => "index_on_recipient_id", :limit => {"recipient_id"=>nil}
  add_index "notification_recipients", ["school_id"], :name => "index_notification_recipients_on_school_id", :limit => {"school_id"=>nil}

  create_table "notifications", :force => true do |t|
    t.text     "content"
    t.string   "initiator"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "payload"
    t.integer  "school_id"
  end

  add_index "notifications", ["initiator"], :name => "index_on_type", :limit => {"initiator"=>nil}
  add_index "notifications", ["school_id"], :name => "index_notifications_on_school_id", :limit => {"school_id"=>nil}

  create_table "number_sequences", :id => false, :force => true do |t|
    t.string   "name"
    t.integer  "next_number",   :default => 1
    t.string   "sequence_type",                :null => false
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "number_sequences", ["name", "sequence_type", "school_id"], :name => "index_by_name_and_sequence_type_and_school_id", :unique => true, :limit => {"name"=>nil, "school_id"=>nil, "sequence_type"=>nil}

  create_table "oauth_authorizations", :force => true do |t|
    t.string   "user_id"
    t.integer  "oauth_client_id"
    t.string   "code"
    t.integer  "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "oauth_clients", :force => true do |t|
    t.string   "name"
    t.string   "client_id"
    t.string   "client_secret"
    t.string   "redirect_uri"
    t.boolean  "verified"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "oauth_tokens", :force => true do |t|
    t.string   "user_id"
    t.integer  "oauth_client_id"
    t.string   "access_token"
    t.string   "refresh_token"
    t.integer  "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_tokens", ["access_token"], :name => "index_to_access_token", :limit => {"access_token"=>nil}
  add_index "oauth_tokens", ["user_id"], :name => "index_to_user_id", :limit => {"user_id"=>nil}

  create_table "observation_groups", :force => true do |t|
    t.string   "name"
    t.string   "header_name"
    t.string   "desc"
    t.string   "cce_grade_set_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "observation_kind"
    t.float    "max_marks"
    t.boolean  "is_deleted",         :default => false
    t.integer  "sort_order"
    t.integer  "di_count_in_report"
    t.integer  "school_id"
  end

  add_index "observation_groups", ["school_id"], :name => "index_observation_groups_on_school_id", :limit => {"school_id"=>nil}

  create_table "observation_remarks", :force => true do |t|
    t.text     "remark"
    t.integer  "observation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "observation_remarks", ["school_id"], :name => "index_observation_remarks_on_school_id", :limit => {"school_id"=>nil}

  create_table "observations", :force => true do |t|
    t.string   "name"
    t.string   "desc"
    t.boolean  "is_active"
    t.integer  "observation_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_order"
    t.integer  "school_id"
  end

  add_index "observations", ["observation_group_id"], :name => "index_observations_on_observation_group_id", :limit => {"observation_group_id"=>nil}
  add_index "observations", ["school_id"], :name => "index_observations_on_school_id", :limit => {"school_id"=>nil}

  create_table "online_exam_attendances", :force => true do |t|
    t.integer  "online_exam_group_id"
    t.integer  "student_id"
    t.datetime "start_time"
    t.datetime "end_time"
    t.decimal  "total_score",          :precision => 7, :scale => 2
    t.boolean  "is_passed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.boolean  "answers_evaluated",                                  :default => false
    t.integer  "batch_id"
    t.boolean  "is_deleted",                                         :default => false
  end

  add_index "online_exam_attendances", ["online_exam_group_id", "student_id"], :name => "by_exam_and_student", :limit => {"student_id"=>nil, "online_exam_group_id"=>nil}
  add_index "online_exam_attendances", ["school_id"], :name => "index_online_exam_attendances_on_school_id", :limit => {"school_id"=>nil}

  create_table "online_exam_groups", :force => true do |t|
    t.string   "name"
    t.date     "start_date"
    t.date     "end_date"
    t.decimal  "maximum_time",        :precision => 7, :scale => 2
    t.decimal  "pass_percentage",     :precision => 6, :scale => 2
    t.integer  "option_count"
    t.integer  "batch_id"
    t.boolean  "is_deleted",                                        :default => false
    t.boolean  "is_published",                                      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.string   "exam_type"
    t.string   "exam_format"
    t.boolean  "result_published",                                  :default => false
    t.boolean  "randomize_questions",                               :default => false
  end

  add_index "online_exam_groups", ["school_id"], :name => "index_online_exam_groups_on_school_id", :limit => {"school_id"=>nil}

  create_table "online_exam_groups_batches", :id => false, :force => true do |t|
    t.integer "online_exam_group_id"
    t.integer "batch_id"
  end

  add_index "online_exam_groups_batches", ["batch_id"], :name => "index_online_exam_groups_batches_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "online_exam_groups_batches", ["online_exam_group_id"], :name => "index_online_exam_groups_batches_on_online_exam_group_id", :limit => {"online_exam_group_id"=>nil}

  create_table "online_exam_groups_employees", :id => false, :force => true do |t|
    t.integer "online_exam_group_id"
    t.integer "employee_id"
  end

  add_index "online_exam_groups_employees", ["employee_id"], :name => "index_online_exam_groups_employees_on_employee_id", :limit => {"employee_id"=>nil}
  add_index "online_exam_groups_employees", ["online_exam_group_id"], :name => "index_online_exam_groups_employees_on_online_exam_group_id", :limit => {"online_exam_group_id"=>nil}

  create_table "online_exam_groups_questions", :force => true do |t|
    t.integer  "online_exam_group_id"
    t.integer  "online_exam_question_id"
    t.decimal  "mark",                    :precision => 15, :scale => 4
    t.text     "answer_ids"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "online_exam_groups_questions", ["online_exam_question_id", "online_exam_group_id"], :name => "groups_questions_unique_index", :unique => true, :limit => {"online_exam_question_id"=>nil, "online_exam_group_id"=>nil}
  add_index "online_exam_groups_questions", ["school_id"], :name => "index_online_exam_groups_questions_on_school_id", :limit => {"school_id"=>nil}

  create_table "online_exam_groups_students", :id => false, :force => true do |t|
    t.integer "online_exam_group_id"
    t.integer "student_id"
  end

  add_index "online_exam_groups_students", ["online_exam_group_id"], :name => "index_online_exam_groups_students_on_online_exam_group_id", :limit => {"online_exam_group_id"=>nil}
  add_index "online_exam_groups_students", ["student_id"], :name => "index_online_exam_groups_students_on_student_id", :limit => {"student_id"=>nil}

  create_table "online_exam_groups_subjects", :id => false, :force => true do |t|
    t.integer "online_exam_group_id"
    t.integer "subject_id"
  end

  add_index "online_exam_groups_subjects", ["online_exam_group_id"], :name => "index_online_exam_groups_subjects_on_online_exam_group_id", :limit => {"online_exam_group_id"=>nil}

  create_table "online_exam_options", :force => true do |t|
    t.integer  "online_exam_question_id"
    t.text     "option"
    t.boolean  "is_answer"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "online_exam_options", ["is_answer"], :name => "index_online_exam_options_on_is_answer", :limit => {"is_answer"=>nil}
  add_index "online_exam_options", ["online_exam_question_id"], :name => "index_online_exam_options_on_online_exam_question_id", :limit => {"online_exam_question_id"=>nil}
  add_index "online_exam_options", ["school_id"], :name => "index_online_exam_options_on_school_id", :limit => {"school_id"=>nil}

  create_table "online_exam_questions", :force => true do |t|
    t.integer  "online_exam_group_id"
    t.text     "question"
    t.decimal  "mark",                 :precision => 7, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.integer  "subject_id"
    t.string   "question_format"
  end

  add_index "online_exam_questions", ["question_format", "subject_id"], :name => "by_format_and_subject", :limit => {"question_format"=>nil, "subject_id"=>nil}
  add_index "online_exam_questions", ["school_id"], :name => "index_online_exam_questions_on_school_id", :limit => {"school_id"=>nil}

  create_table "online_exam_score_details", :force => true do |t|
    t.integer  "online_exam_question_id"
    t.integer  "online_exam_attendance_id"
    t.integer  "online_exam_option_id"
    t.boolean  "is_correct"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.integer  "online_exam_group_id"
    t.decimal  "marks_obtained",            :precision => 15, :scale => 2
    t.text     "answer"
    t.boolean  "is_deleted",                                               :default => false
  end

  add_index "online_exam_score_details", ["online_exam_attendance_id"], :name => "index_online_exam_score_details_on_online_exam_attendance_id", :limit => {"online_exam_attendance_id"=>nil}
  add_index "online_exam_score_details", ["online_exam_option_id", "online_exam_question_id", "online_exam_attendance_id"], :name => "score_details_index", :limit => {"online_exam_attendance_id"=>nil, "online_exam_option_id"=>nil, "online_exam_question_id"=>nil}
  add_index "online_exam_score_details", ["online_exam_option_id", "online_exam_question_id", "online_exam_attendance_id"], :name => "score_details_unique_index", :unique => true, :limit => {"online_exam_attendance_id"=>nil, "online_exam_option_id"=>nil, "online_exam_question_id"=>nil}
  add_index "online_exam_score_details", ["school_id"], :name => "index_online_exam_score_details_on_school_id", :limit => {"school_id"=>nil}

  create_table "override_assessment_marks", :force => true do |t|
    t.integer  "assessment_group_id"
    t.string   "subject_name"
    t.string   "subject_code"
    t.integer  "course_id"
    t.decimal  "maximum_marks",       :precision => 10, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "override_assessment_marks", ["school_id"], :name => "index_override_assessment_marks_on_school_id", :limit => {"school_id"=>nil}

  create_table "palette_queries", :force => true do |t|
    t.integer  "palette_id"
    t.text     "user_roles"
    t.text     "query"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "parameters"
  end

  create_table "palettes", :force => true do |t|
    t.string   "name"
    t.string   "model_name"
    t.string   "icon"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "plugin"
  end

  add_index "palettes", ["name"], :name => "index_palettes_on_name", :limit => {"name"=>nil}

  create_table "particular_discounts", :force => true do |t|
    t.decimal  "discount",              :precision => 15, :scale => 4
    t.integer  "particular_payment_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_active",                                            :default => true
    t.integer  "school_id"
  end

  add_index "particular_discounts", ["is_active"], :name => "is_active", :limit => {"is_active"=>nil}
  add_index "particular_discounts", ["particular_payment_id"], :name => "index_particular_discounts_on_particular_payment_id", :limit => {"particular_payment_id"=>nil}
  add_index "particular_discounts", ["school_id"], :name => "index_particular_discounts_on_school_id", :limit => {"school_id"=>nil}

  create_table "particular_payments", :force => true do |t|
    t.decimal  "amount",                    :precision => 15, :scale => 4
    t.integer  "finance_fee_id"
    t.integer  "finance_fee_particular_id"
    t.integer  "finance_transaction_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "transaction_date"
    t.boolean  "is_active",                                                :default => true
    t.integer  "school_id"
  end

  add_index "particular_payments", ["finance_fee_id"], :name => "index_particular_payments_on_finance_fee_id", :limit => {"finance_fee_id"=>nil}
  add_index "particular_payments", ["finance_fee_particular_id", "finance_transaction_id"], :name => "particular_payment_uniqueness", :unique => true, :limit => {"finance_transaction_id"=>nil, "finance_fee_particular_id"=>nil}
  add_index "particular_payments", ["finance_transaction_id"], :name => "index_on_finance_transaction_id", :limit => {"finance_transaction_id"=>nil}
  add_index "particular_payments", ["is_active"], :name => "is_active", :limit => {"is_active"=>nil}
  add_index "particular_payments", ["school_id"], :name => "index_particular_payments_on_school_id", :limit => {"school_id"=>nil}

  create_table "payment_accounts", :force => true do |t|
    t.integer  "custom_gateway_id"
    t.integer  "collection_id"
    t.string   "collection_type"
    t.text     "account_params"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payment_configurations", :force => true do |t|
    t.string   "config_key"
    t.string   "config_value"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payment_requests", :force => true do |t|
    t.text     "identification_token"
    t.text     "transaction_parameters"
    t.integer  "user_id"
    t.boolean  "is_processed",           :default => false
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payments", :force => true do |t|
    t.string   "payee_type"
    t.integer  "payee_id"
    t.text     "gateway_response"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "status"
    t.decimal  "amount",                    :precision => 15, :scale => 4
    t.integer  "status_description"
    t.string   "gateway"
    t.string   "type"
    t.integer  "multi_fees_transaction_id"
    t.boolean  "is_pending",                                               :default => false
  end

  add_index "payments", ["created_at"], :name => "by_creation", :limit => {"created_at"=>nil}
  add_index "payments", ["payee_id"], :name => "index_payments_on_payee_id", :limit => {"payee_id"=>nil}
  add_index "payments", ["status"], :name => "index_payments_on_status", :limit => {"status"=>nil}

  create_table "payroll_categories", :force => true do |t|
    t.string   "name"
    t.float    "percentage"
    t.integer  "payroll_category_id"
    t.boolean  "is_deduction"
    t.boolean  "status"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.boolean  "is_deleted",           :default => false
    t.string   "code"
    t.text     "dependant_categories"
    t.integer  "school_id"
    t.boolean  "gross_dependent",      :default => false
    t.integer  "round_off_value"
  end

  add_index "payroll_categories", ["code", "school_id"], :name => "pc_code_unique_index", :unique => true, :limit => {"code"=>nil, "school_id"=>nil}
  add_index "payroll_categories", ["school_id"], :name => "index_payroll_categories_on_school_id", :limit => {"school_id"=>nil}

  create_table "payroll_group_revisions", :force => true do |t|
    t.integer "payroll_group_id"
    t.integer "revision_number"
    t.text    "categories"
    t.integer "school_id"
  end

  add_index "payroll_group_revisions", ["payroll_group_id"], :name => "index_payroll_group_revisions_on_payroll_group_id", :limit => {"payroll_group_id"=>nil}
  add_index "payroll_group_revisions", ["school_id"], :name => "index_payroll_group_revisions_on_school_id", :limit => {"school_id"=>nil}

  create_table "payroll_groups", :force => true do |t|
    t.string   "name"
    t.integer  "salary_type"
    t.integer  "payment_period"
    t.integer  "generation_day"
    t.boolean  "enable_lop",       :default => false
    t.integer  "current_revision", :default => 1
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "payroll_groups", ["name", "school_id"], :name => "pg_name_unique_index", :unique => true, :limit => {"name"=>nil, "school_id"=>nil}

  create_table "payroll_groups_payroll_categories", :force => true do |t|
    t.integer  "payroll_group_id"
    t.integer  "payroll_category_id"
    t.integer  "sort_order"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "payroll_groups_payroll_categories", ["payroll_category_id"], :name => "index_payroll_groups_payroll_categories_on_payroll_category_id", :limit => {"payroll_category_id"=>nil}
  add_index "payroll_groups_payroll_categories", ["payroll_group_id"], :name => "index_payroll_groups_payroll_categories_on_payroll_group_id", :limit => {"payroll_group_id"=>nil}
  add_index "payroll_groups_payroll_categories", ["school_id"], :name => "index_payroll_groups_payroll_categories_on_school_id", :limit => {"school_id"=>nil}

  create_table "payroll_revisions", :force => true do |t|
    t.integer  "employee_salary_structure_id"
    t.text     "payroll_details"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "payroll_revisions", ["school_id"], :name => "index_payroll_revisions_on_school_id", :limit => {"school_id"=>nil}

  create_table "payslip_additional_leaves", :force => true do |t|
    t.integer  "employee_payslip_id"
    t.integer  "employee_additional_leave_id"
    t.date     "attendance_date"
    t.boolean  "is_half_day"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "payslip_additional_leaves", ["school_id"], :name => "index_payslip_additional_leaves_on_school_id", :limit => {"school_id"=>nil}

  create_table "payslip_settings", :force => true do |t|
    t.string   "section"
    t.text     "fields"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "payslip_settings", ["school_id"], :name => "index_payslip_settings_on_school_id", :limit => {"school_id"=>nil}

  create_table "payslips_date_ranges", :force => true do |t|
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "payroll_group_id"
    t.integer  "revision_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "payslips_date_ranges", ["end_date"], :name => "index_payslips_date_ranges_on_end_date", :limit => {"end_date"=>nil}
  add_index "payslips_date_ranges", ["payroll_group_id", "start_date", "end_date"], :name => "date_range_unique_within_payroll_group", :unique => true, :limit => {"start_date"=>nil, "payroll_group_id"=>nil, "end_date"=>nil}
  add_index "payslips_date_ranges", ["payroll_group_id"], :name => "index_payslips_date_ranges_on_payroll_group_id", :limit => {"payroll_group_id"=>nil}
  add_index "payslips_date_ranges", ["school_id"], :name => "index_payslips_date_ranges_on_school_id", :limit => {"school_id"=>nil}
  add_index "payslips_date_ranges", ["start_date", "end_date"], :name => "index_payslips_date_ranges_on_start_date_and_end_date", :limit => {"start_date"=>nil, "end_date"=>nil}
  add_index "payslips_date_ranges", ["start_date"], :name => "index_payslips_date_ranges_on_start_date", :limit => {"start_date"=>nil}

  create_table "paytm_payment_records", :force => true do |t|
    t.integer  "transaction_ledger_id"
    t.integer  "order_id"
    t.integer  "item_id"
    t.decimal  "amount",                :precision => 15, :scale => 4
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "period_entries", :force => true do |t|
    t.date     "month_date"
    t.integer  "batch_id"
    t.integer  "subject_id"
    t.integer  "class_timing_id"
    t.integer  "employee_id"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "period_entries", ["month_date", "batch_id"], :name => "index_period_entries_on_month_date_and_batch_id", :limit => {"month_date"=>nil, "batch_id"=>nil}
  add_index "period_entries", ["school_id"], :name => "index_period_entries_on_school_id", :limit => {"school_id"=>nil}

  create_table "pin_groups", :force => true do |t|
    t.text     "course_ids"
    t.date     "valid_from"
    t.date     "valid_till"
    t.string   "name"
    t.integer  "pin_count"
    t.boolean  "is_active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  create_table "pin_numbers", :force => true do |t|
    t.string   "number"
    t.boolean  "is_active"
    t.boolean  "is_registered"
    t.integer  "pin_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  create_table "placement_registrations", :force => true do |t|
    t.integer  "student_id"
    t.integer  "placementevent_id"
    t.boolean  "is_applied",        :default => false
    t.boolean  "is_approved"
    t.boolean  "is_attended",       :default => false
    t.boolean  "is_placed",         :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "placement_registrations", ["school_id"], :name => "index_placement_registrations_on_school_id", :limit => {"school_id"=>nil}

  create_table "placementevents", :force => true do |t|
    t.string   "title"
    t.string   "company"
    t.string   "place"
    t.text     "description"
    t.boolean  "is_active",   :default => true
    t.datetime "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "placementevents", ["school_id"], :name => "index_placementevents_on_school_id", :limit => {"school_id"=>nil}

  create_table "poll_members", :force => true do |t|
    t.integer  "poll_question_id"
    t.integer  "member_id"
    t.string   "member_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "poll_members", ["school_id"], :name => "index_poll_members_on_school_id", :limit => {"school_id"=>nil}

  create_table "poll_options", :force => true do |t|
    t.integer  "poll_question_id"
    t.text     "option"
    t.integer  "sort_order"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "poll_options", ["school_id"], :name => "index_poll_options_on_school_id", :limit => {"school_id"=>nil}

  create_table "poll_questions", :force => true do |t|
    t.boolean  "is_active"
    t.string   "title"
    t.text     "description"
    t.boolean  "allow_custom_ans"
    t.integer  "poll_creator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "poll_questions", ["school_id"], :name => "index_poll_questions_on_school_id", :limit => {"school_id"=>nil}

  create_table "poll_votes", :force => true do |t|
    t.integer  "poll_question_id"
    t.integer  "poll_option_id"
    t.string   "custom_answer"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "poll_votes", ["school_id"], :name => "index_poll_votes_on_school_id", :limit => {"school_id"=>nil}

  create_table "previous_exam_scores", :force => true do |t|
    t.integer  "student_id"
    t.integer  "exam_id"
    t.decimal  "marks",            :precision => 7, :scale => 2
    t.integer  "grading_level_id"
    t.string   "remarks"
    t.boolean  "is_failed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "previous_exam_scores", ["school_id"], :name => "index_previous_exam_scores_on_school_id", :limit => {"school_id"=>nil}
  add_index "previous_exam_scores", ["student_id", "exam_id"], :name => "index_previous_exam_scores_on_student_id_and_exam_id", :limit => {"student_id"=>nil, "exam_id"=>nil}

  create_table "privilege_tags", :force => true do |t|
    t.string   "name_tag"
    t.integer  "priority"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "privileged_folder_groups", :force => true do |t|
    t.integer  "user_id"
    t.integer  "linkable_id"
    t.string   "linkable_type"
    t.integer  "privileged_folder_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "privileged_folder_groups", ["school_id"], :name => "index_privileged_folder_groups_on_school_id", :limit => {"school_id"=>nil}

  create_table "privileged_folders_users", :id => false, :force => true do |t|
    t.integer "privileged_folder_id"
    t.integer "user_id"
  end

  create_table "privileges", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.integer  "privilege_tag_id"
    t.integer  "priority"
  end

  create_table "privileges_users", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "privilege_id"
  end

  add_index "privileges_users", ["user_id"], :name => "index_privileges_users_on_user_id", :limit => {"user_id"=>nil}

  create_table "purchase_items", :force => true do |t|
    t.integer  "quantity"
    t.decimal  "discount",          :precision => 10, :scale => 4
    t.decimal  "tax",               :precision => 10, :scale => 4
    t.decimal  "price",             :precision => 12, :scale => 4
    t.boolean  "is_deleted",                                       :default => false
    t.integer  "user_id"
    t.integer  "purchase_order_id"
    t.integer  "store_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "purchase_items", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "purchase_orders", :force => true do |t|
    t.string   "po_no"
    t.datetime "po_date"
    t.string   "po_status",        :default => "Pending"
    t.string   "reference"
    t.boolean  "is_deleted",       :default => false
    t.integer  "store_id"
    t.integer  "indent_id"
    t.integer  "supplier_id"
    t.integer  "supplier_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "purchase_orders", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "ranking_levels", :force => true do |t|
    t.string   "name",                                                                 :null => false
    t.decimal  "gpa",                :precision => 15, :scale => 2
    t.decimal  "marks",              :precision => 15, :scale => 2
    t.integer  "subject_count"
    t.integer  "priority"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "full_course",                                       :default => false
    t.integer  "course_id"
    t.string   "subject_limit_type"
    t.string   "marks_limit_type"
    t.integer  "school_id"
  end

  add_index "ranking_levels", ["school_id"], :name => "index_ranking_levels_on_school_id", :limit => {"school_id"=>nil}

  create_table "receipt_number_sets", :force => true do |t|
    t.string   "name",            :null => false
    t.string   "sequence_prefix"
    t.string   "starting_number", :null => false
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "receipt_number_sets", ["name"], :name => "index_by_name", :limit => {"name"=>nil}
  add_index "receipt_number_sets", ["school_id"], :name => "index_on_school_id", :limit => {"school_id"=>nil}
  add_index "receipt_number_sets", ["sequence_prefix", "school_id"], :name => "unique_sequence_prefix_in_school", :unique => true, :limit => {"sequence_prefix"=>nil, "school_id"=>nil}
  add_index "receipt_number_sets", ["sequence_prefix"], :name => "by_sequence_prefix", :limit => {"sequence_prefix"=>nil}

  create_table "record_addl_attachments", :force => true do |t|
    t.integer  "student_record_id"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "record_addl_attachments", ["school_id"], :name => "index_record_addl_attachments_on_school_id", :limit => {"school_id"=>nil}

  create_table "record_assignments", :force => true do |t|
    t.integer  "course_id"
    t.integer  "record_group_id"
    t.integer  "priority"
    t.boolean  "add_for_future",  :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "record_assignments", ["course_id"], :name => "index_record_assignments_on_course_id", :limit => {"course_id"=>nil}
  add_index "record_assignments", ["record_group_id"], :name => "index_record_assignments_on_record_group_id", :limit => {"record_group_id"=>nil}
  add_index "record_assignments", ["school_id"], :name => "index_record_assignments_on_school_id", :limit => {"school_id"=>nil}

  create_table "record_batch_assignments", :force => true do |t|
    t.integer  "record_group_id"
    t.integer  "batch_id"
    t.integer  "record_assignment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "record_batch_assignments", ["batch_id"], :name => "index_record_batch_assignments_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "record_batch_assignments", ["record_assignment_id"], :name => "index_record_batch_assignments_on_record_assignment_id", :limit => {"record_assignment_id"=>nil}
  add_index "record_batch_assignments", ["record_group_id"], :name => "index_record_batch_assignments_on_record_group_id", :limit => {"record_group_id"=>nil}
  add_index "record_batch_assignments", ["school_id"], :name => "index_record_batch_assignments_on_school_id", :limit => {"school_id"=>nil}

  create_table "record_field_options", :force => true do |t|
    t.string   "field_option"
    t.boolean  "is_default",   :default => false
    t.integer  "record_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "record_field_options", ["school_id"], :name => "index_record_field_options_on_school_id", :limit => {"school_id"=>nil}

  create_table "record_groups", :force => true do |t|
    t.string   "name"
    t.boolean  "is_active",  :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "record_groups", ["school_id"], :name => "index_record_groups_on_school_id", :limit => {"school_id"=>nil}

  create_table "record_updates", :force => true do |t|
    t.string   "file_name"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "record_updates", ["file_name", "school_id"], :name => "index_on_file_name_and_school_id", :limit => {"file_name"=>nil, "school_id"=>nil}

  create_table "records", :force => true do |t|
    t.string   "name"
    t.string   "suffix"
    t.string   "record_type"
    t.integer  "record_group_id"
    t.integer  "priority"
    t.boolean  "is_mandatory"
    t.string   "input_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "records", ["record_group_id"], :name => "index_by_record_group_id", :limit => {"record_group_id"=>nil}
  add_index "records", ["record_group_id"], :name => "index_records_on_record_group_id", :limit => {"record_group_id"=>nil}
  add_index "records", ["school_id"], :name => "index_records_on_school_id", :limit => {"school_id"=>nil}

  create_table "redactor_uploads", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.boolean  "is_used",            :default => false
    t.integer  "school_id"
  end

  add_index "redactor_uploads", ["school_id"], :name => "index_redactor_uploads_on_school_id", :limit => {"school_id"=>nil}

  create_table "refund_rules", :force => true do |t|
    t.integer  "finance_fee_collection_id"
    t.string   "name"
    t.date     "refund_validity"
    t.decimal  "amount",                    :precision => 15, :scale => 4
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_amount",                                                :default => false
    t.integer  "school_id"
  end

  add_index "refund_rules", ["school_id"], :name => "index_refund_rules_on_school_id", :limit => {"school_id"=>nil}

  create_table "registration_courses", :force => true do |t|
    t.integer  "school_id"
    t.integer  "course_id"
    t.integer  "minimum_score"
    t.boolean  "is_active"
    t.float    "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "subject_based_fee_colletion"
    t.boolean  "enable_approval_system"
    t.integer  "min_electives"
    t.integer  "max_electives"
    t.boolean  "is_subject_based_registration"
    t.boolean  "include_additional_details"
    t.string   "additional_field_ids"
    t.boolean  "transfer_documents",            :default => false
    t.string   "display_name"
    t.string   "form_header"
    t.integer  "financial_year_id"
    t.integer  "master_fee_particular_id"
  end

  add_index "registration_courses", ["course_id"], :name => "index_registration_courses_on_course_id", :limit => {"course_id"=>nil}
  add_index "registration_courses", ["financial_year_id"], :name => "index_by_fyid", :limit => {"financial_year_id"=>nil}
  add_index "registration_courses", ["master_fee_particular_id"], :name => "by_master_particular_id", :limit => {"master_fee_particular_id"=>nil}
  add_index "registration_courses", ["school_id"], :name => "index_registration_courses_on_school_id", :limit => {"school_id"=>nil}

  create_table "remark_banks", :force => true do |t|
    t.string  "name"
    t.integer "school_id"
  end

  create_table "remark_parameters", :force => true do |t|
    t.integer  "remark_id"
    t.string   "param_name"
    t.string   "param_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "remark_parameters", ["remark_id"], :name => "index_remark_parameters_on_remark_id", :limit => {"remark_id"=>nil}
  add_index "remark_parameters", ["school_id"], :name => "index_remark_parameters_on_school_id", :limit => {"school_id"=>nil}

  create_table "remark_sets", :force => true do |t|
    t.integer "assessment_plan_id"
    t.string  "name"
    t.string  "target_type"
    t.integer "school_id"
  end

  add_index "remark_sets", ["assessment_plan_id", "target_type"], :name => "index_remark_sets_on_assessment_plan_id_and_target_type", :limit => {"assessment_plan_id"=>nil, "target_type"=>nil}

  create_table "remark_settings", :force => true do |t|
    t.string   "target"
    t.text     "parameters"
    t.string   "table_name"
    t.string   "field_name"
    t.string   "remark_type"
    t.boolean  "general"
    t.string   "load_model"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "remark_templates", :force => true do |t|
    t.integer "remark_bank_id"
    t.string  "name"
    t.string  "template_body"
    t.integer "school_id"
  end

  add_index "remark_templates", ["remark_bank_id"], :name => "index_remark_templates_on_remark_bank_id", :limit => {"remark_bank_id"=>nil}

  create_table "remarks", :force => true do |t|
    t.integer  "target_id"
    t.integer  "student_id"
    t.integer  "batch_id"
    t.integer  "submitted_by"
    t.string   "remark_subject"
    t.text     "remark_body"
    t.string   "remarked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "remarks", ["school_id"], :name => "index_remarks_on_school_id", :limit => {"school_id"=>nil}
  add_index "remarks", ["target_id"], :name => "index_remarks_on_target_id", :limit => {"target_id"=>nil}

  create_table "reminder_attachment_relations", :force => true do |t|
    t.integer  "reminder_id"
    t.integer  "reminder_attachment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "reminder_attachment_relations", ["reminder_id", "reminder_attachment_id"], :name => "reminder_attachment_index", :unique => true, :limit => {"reminder_attachment_id"=>nil, "reminder_id"=>nil}
  add_index "reminder_attachment_relations", ["school_id"], :name => "index_reminder_attachment_relations_on_school_id", :limit => {"school_id"=>nil}

  create_table "reminder_attachments", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.integer  "school_id"
  end

  add_index "reminder_attachments", ["school_id"], :name => "index_reminder_attachments_on_school_id", :limit => {"school_id"=>nil}

  create_table "reminders", :force => true do |t|
    t.integer  "sender"
    t.integer  "recipient"
    t.string   "subject"
    t.text     "body"
    t.boolean  "is_read",                 :default => false
    t.boolean  "is_deleted_by_sender",    :default => false
    t.boolean  "is_deleted_by_recipient", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "reminders", ["recipient"], :name => "index_reminders_on_recipient", :limit => {"recipient"=>nil}
  add_index "reminders", ["school_id"], :name => "index_reminders_on_school_id", :limit => {"school_id"=>nil}

  create_table "report_columns", :force => true do |t|
    t.integer  "report_id"
    t.string   "title"
    t.string   "method"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.string   "association_method"
  end

  add_index "report_columns", ["report_id"], :name => "index_report_columns_on_report_id", :limit => {"report_id"=>nil}
  add_index "report_columns", ["school_id"], :name => "index_report_columns_on_school_id", :limit => {"school_id"=>nil}

  create_table "report_queries", :force => true do |t|
    t.integer  "report_id"
    t.string   "table_name"
    t.string   "column_name"
    t.string   "criteria"
    t.text     "query"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "column_type"
    t.integer  "school_id"
  end

  add_index "report_queries", ["report_id"], :name => "index_report_queries_on_report_id", :limit => {"report_id"=>nil}
  add_index "report_queries", ["school_id"], :name => "index_report_queries_on_school_id", :limit => {"school_id"=>nil}

  create_table "report_settings", :force => true do |t|
    t.string   "setting_key"
    t.string   "setting_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "report_settings", ["school_id"], :name => "index_report_settings_on_school_id", :limit => {"school_id"=>nil}

  create_table "reports", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "model"
    t.integer  "school_id"
  end

  add_index "reports", ["school_id"], :name => "index_reports_on_school_id", :limit => {"school_id"=>nil}

  create_table "room_additional_field_options", :force => true do |t|
    t.string   "field_option"
    t.integer  "room_additional_field_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "room_allocations", :force => true do |t|
    t.integer  "room_detail_id"
    t.integer  "student_id"
    t.boolean  "is_vacated",     :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "room_allocations", ["room_detail_id"], :name => "index_room_allocations_on_room_detail_id", :limit => {"room_detail_id"=>nil}
  add_index "room_allocations", ["school_id"], :name => "index_room_allocations_on_school_id", :limit => {"school_id"=>nil}

  create_table "room_details", :force => true do |t|
    t.integer  "hostel_id"
    t.string   "room_number"
    t.integer  "students_per_room"
    t.decimal  "rent",              :precision => 15, :scale => 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "room_details", ["hostel_id"], :name => "index_room_details_on_hostel_id", :limit => {"hostel_id"=>nil}
  add_index "room_details", ["school_id"], :name => "index_room_details_on_school_id", :limit => {"school_id"=>nil}

  create_table "route_additional_field_options", :force => true do |t|
    t.string   "field_option"
    t.integer  "route_additional_field_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "route_employees", :force => true do |t|
    t.integer  "employee_id"
    t.string   "mobile_phone"
    t.integer  "task"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "route_employees", ["employee_id"], :name => "index_route_employees_on_employee_id", :limit => {"employee_id"=>nil}
  add_index "route_employees", ["school_id"], :name => "index_route_employees_on_school_id", :limit => {"school_id"=>nil}

  create_table "route_stops", :force => true do |t|
    t.integer  "route_id"
    t.integer  "vehicle_stop_id"
    t.integer  "stop_order"
    t.time     "pickup_time"
    t.time     "drop_time"
    t.decimal  "fare",            :precision => 15, :scale => 4
    t.decimal  "distance",        :precision => 15, :scale => 4
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "route_stops", ["route_id"], :name => "index_route_stops_on_route_id", :limit => {"route_id"=>nil}
  add_index "route_stops", ["school_id"], :name => "index_route_stops_on_school_id", :limit => {"school_id"=>nil}
  add_index "route_stops", ["vehicle_stop_id"], :name => "index_route_stops_on_vehicle_stop_id", :limit => {"vehicle_stop_id"=>nil}

  create_table "routes", :force => true do |t|
    t.string   "name"
    t.decimal  "fare",                 :precision => 15, :scale => 4
    t.integer  "main_route_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.integer  "academic_year_id"
    t.integer  "vehicle_id"
    t.integer  "driver_id"
    t.integer  "attendant_id"
    t.integer  "fare_updating_status"
    t.boolean  "is_active",                                           :default => true
  end

  add_index "routes", ["academic_year_id", "is_active", "school_id"], :name => "index_on_active_in_academic_year", :limit => {"is_active"=>nil, "school_id"=>nil, "academic_year_id"=>nil}
  add_index "routes", ["academic_year_id"], :name => "index_routes_on_academic_year_id", :limit => {"academic_year_id"=>nil}
  add_index "routes", ["attendant_id"], :name => "index_routes_on_attendant_id", :limit => {"attendant_id"=>nil}
  add_index "routes", ["driver_id"], :name => "index_routes_on_driver_id", :limit => {"driver_id"=>nil}
  add_index "routes", ["is_active", "academic_year_id"], :name => "index_routes_on_is_active_and_academic_year_id", :limit => {"is_active"=>nil, "academic_year_id"=>nil}
  add_index "routes", ["is_active"], :name => "index_routes_on_is_active", :limit => {"is_active"=>nil}
  add_index "routes", ["school_id"], :name => "index_routes_on_school_id", :limit => {"school_id"=>nil}
  add_index "routes", ["vehicle_id"], :name => "index_routes_on_vehicle_id", :limit => {"vehicle_id"=>nil}

  create_table "salary_working_days", :force => true do |t|
    t.integer  "payment_period"
    t.integer  "working_days"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "month_value"
    t.integer  "school_id"
  end

  add_index "salary_working_days", ["school_id"], :name => "index_salary_working_days_on_school_id", :limit => {"school_id"=>nil}

  create_table "sales_user_details", :force => true do |t|
    t.integer  "user_id"
    t.string   "username"
    t.string   "address"
    t.integer  "batch_id"
    t.integer  "invoice_id"
    t.string   "invoice_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.integer  "issuer_id"
  end

  add_index "sales_user_details", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "school_assets", :force => true do |t|
    t.string   "asset_name"
    t.string   "asset_description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "school_assets", ["school_id"], :name => "index_school_assets_on_school_id", :limit => {"school_id"=>nil}

  create_table "school_details", :force => true do |t|
    t.integer  "school_id"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.string   "logo_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "logo_updated_at"
  end

  create_table "school_domains", :force => true do |t|
    t.string   "domain"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "linkable_id"
    t.string   "linkable_type"
    t.boolean  "is_primary",    :default => false
  end

  add_index "school_domains", ["linkable_id", "linkable_type"], :name => "index_school_domains_on_linkable_id_and_linkable_type", :limit => {"linkable_id"=>nil, "linkable_type"=>nil}

  create_table "school_group_users", :force => true do |t|
    t.integer  "admin_user_id"
    t.integer  "school_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "school_group_users", ["admin_user_id"], :name => "index_school_group_users_on_admin_user_id", :limit => {"admin_user_id"=>nil}
  add_index "school_group_users", ["school_group_id"], :name => "index_school_group_users_on_school_group_id", :limit => {"school_group_id"=>nil}

  create_table "school_groups", :force => true do |t|
    t.string   "name"
    t.integer  "admin_user_id"
    t.integer  "parent_group_id"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "whitelabel_enabled",    :default => false
    t.integer  "license_count"
    t.boolean  "inherit_sms_settings",  :default => false
    t.boolean  "inherit_smtp_settings", :default => false
    t.boolean  "is_deleted",            :default => false
    t.string   "fin"
    t.boolean  "school_stats_enabled",  :default => false
    t.boolean  "gps_enabled",           :default => false
  end

  add_index "school_groups", ["id", "type"], :name => "index_school_groups_on_id_and_type", :limit => {"type"=>nil, "id"=>nil}
  add_index "school_groups", ["type", "is_deleted"], :name => "index_school_groups_on_type_and_is_deleted", :limit => {"type"=>nil, "is_deleted"=>nil}
  add_index "school_groups", ["type", "parent_group_id", "is_deleted"], :name => "index_of_parent_group_on_active_group", :limit => {"type"=>nil, "is_deleted"=>nil, "parent_group_id"=>nil}
  add_index "school_groups", ["type", "parent_group_id"], :name => "index_school_groups_on_type_and_parent_group_id", :limit => {"type"=>nil, "parent_group_id"=>nil}
  add_index "school_groups", ["type"], :name => "index_school_groups_on_type", :limit => {"type"=>nil}

  create_table "school_stats", :force => true do |t|
    t.text     "live_stats"
    t.integer  "admin_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "schools", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_seeded_at"
    t.boolean  "is_deleted",            :default => false
    t.integer  "school_group_id"
    t.integer  "creator_id"
    t.boolean  "inherit_sms_settings",  :default => false
    t.boolean  "inherit_smtp_settings", :default => false
    t.boolean  "access_locked",         :default => false
    t.boolean  "gps_enabled",           :default => false
    t.boolean  "edit_sms_template",     :default => false
  end

  add_index "schools", ["is_deleted"], :name => "index_schools_on_is_deleted", :limit => {"is_deleted"=>nil}
  add_index "schools", ["school_group_id", "is_deleted"], :name => "index_schools_on_school_group_id_and_is_deleted", :limit => {"is_deleted"=>nil, "school_group_id"=>nil}

  create_table "shareable_folder_users", :force => true do |t|
    t.integer  "user_id"
    t.integer  "shareable_folder_id"
    t.boolean  "is_favorite",         :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "shareable_folder_users", ["school_id"], :name => "index_shareable_folder_users_on_school_id", :limit => {"school_id"=>nil}
  add_index "shareable_folder_users", ["user_id", "shareable_folder_id"], :name => "index_shareable_folder_users_on_user_id_and_shareable_folder_id", :limit => {"shareable_folder_id"=>nil, "user_id"=>nil}

  create_table "single_access_tokens", :force => true do |t|
    t.string   "client_name"
    t.string   "access_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "single_statement_headers", :force => true do |t|
    t.integer  "school_id"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.string   "logo_file_size"
    t.boolean  "is_empty"
    t.string   "title"
    t.integer  "space_height"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "logo_updated_at"
  end

  create_table "skill_assessments", :force => true do |t|
    t.integer  "subject_id"
    t.integer  "subject_skill_id"
    t.integer  "subject_assessment_id"
    t.boolean  "marks_added",               :default => false
    t.integer  "submission_status"
    t.boolean  "edited",                    :default => false
    t.integer  "higher_assessment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "assessment_group_batch_id"
    t.integer  "school_id"
  end

  add_index "skill_assessments", ["assessment_group_batch_id"], :name => "index_skill_assessments_on_assessment_group_batch_id", :limit => {"assessment_group_batch_id"=>nil}
  add_index "skill_assessments", ["school_id"], :name => "index_skill_assessments_on_school_id", :limit => {"school_id"=>nil}

  create_table "sms_logs", :force => true do |t|
    t.text     "mobile"
    t.string   "gateway_response"
    t.string   "sms_message_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "message"
    t.integer  "user_id"
    t.string   "user_name"
    t.integer  "school_id"
  end

  add_index "sms_logs", ["school_id"], :name => "index_sms_logs_on_school_id", :limit => {"school_id"=>nil}

  create_table "sms_messages", :force => true do |t|
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "group_id"
    t.string   "group_type"
    t.string   "message_type",      :default => "plain_message"
    t.boolean  "automated_message"
    t.integer  "school_id"
  end

  add_index "sms_messages", ["automated_message"], :name => "index_by_automated_message", :limit => {"automated_message"=>nil}
  add_index "sms_messages", ["message_type"], :name => "index_by_message_type", :limit => {"message_type"=>nil}
  add_index "sms_messages", ["school_id"], :name => "index_sms_messages_on_school_id", :limit => {"school_id"=>nil}

  create_table "sms_packages", :force => true do |t|
    t.string   "name"
    t.string   "service_provider"
    t.integer  "message_limit"
    t.date     "validity"
    t.text     "settings"
    t.boolean  "enable_sendername_modification", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "character_limit"
    t.integer  "multipart_character_limit"
  end

  create_table "sms_settings", :force => true do |t|
    t.string   "settings_key"
    t.boolean  "is_enabled",   :default => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "user_type"
    t.integer  "school_id"
  end

  add_index "sms_settings", ["school_id"], :name => "index_sms_settings_on_school_id", :limit => {"school_id"=>nil}

  create_table "sold_items", :force => true do |t|
    t.integer  "store_item_id"
    t.integer  "invoice_id"
    t.integer  "quantity"
    t.string   "code"
    t.string   "invoice_type"
    t.decimal  "rate",          :precision => 15, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "sold_items", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "stat_bookmarks", :force => true do |t|
    t.string   "name"
    t.text     "url"
    t.integer  "admin_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "store_categories", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.boolean  "is_deleted", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "store_categories", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "store_items", :force => true do |t|
    t.string   "item_name"
    t.integer  "quantity"
    t.decimal  "unit_price",       :precision => 12, :scale => 4
    t.decimal  "tax",              :precision => 10, :scale => 4
    t.string   "batch_number"
    t.boolean  "is_deleted",                                      :default => false
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.string   "code"
    t.boolean  "sellable"
    t.integer  "item_category_id"
  end

  add_index "store_items", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "store_types", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.boolean  "is_deleted", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "store_types", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "stores", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.boolean  "is_deleted",        :default => false
    t.integer  "store_category_id"
    t.integer  "store_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.string   "invoice_prefix"
  end

  add_index "stores", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "student_additional_details", :force => true do |t|
    t.integer  "student_id"
    t.integer  "additional_field_id"
    t.text     "additional_info"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "student_additional_details", ["school_id"], :name => "index_student_additional_details_on_school_id", :limit => {"school_id"=>nil}
  add_index "student_additional_details", ["student_id", "additional_field_id"], :name => "student_data_index", :limit => {"student_id"=>nil, "additional_field_id"=>nil}

  create_table "student_additional_field_options", :force => true do |t|
    t.integer  "student_additional_field_id"
    t.string   "field_option"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "student_additional_field_options", ["school_id"], :name => "index_student_additional_field_options_on_school_id", :limit => {"school_id"=>nil}

  create_table "student_additional_fields", :force => true do |t|
    t.string   "name"
    t.boolean  "status"
    t.boolean  "is_mandatory", :default => false
    t.string   "input_type"
    t.integer  "priority"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "student_additional_fields", ["school_id"], :name => "index_student_additional_fields_on_school_id", :limit => {"school_id"=>nil}

  create_table "student_addl_attachments", :force => true do |t|
    t.integer  "school_id"
    t.integer  "student_id"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "student_addl_attachments", ["student_id"], :name => "index_student_addl_attachments_on_student_id", :limit => {"student_id"=>nil}

  create_table "student_attachment_categories", :force => true do |t|
    t.string   "attachment_category_name"
    t.boolean  "is_deletable",             :default => false
    t.integer  "creator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "student_attachment_categories", ["school_id"], :name => "index_student_attachment_categories_on_school_id", :limit => {"school_id"=>nil}

  create_table "student_attachment_records", :force => true do |t|
    t.integer  "student_attachment_id"
    t.integer  "student_attachment_category_id"
    t.integer  "record_manager_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "student_attachment_records", ["school_id"], :name => "index_student_attachment_records_on_school_id", :limit => {"school_id"=>nil}
  add_index "student_attachment_records", ["student_attachment_category_id"], :name => "index_on_student_attachment_category_id", :limit => {"student_attachment_category_id"=>nil}
  add_index "student_attachment_records", ["student_attachment_id"], :name => "index_on_student_attachment_id", :limit => {"student_attachment_id"=>nil}

  create_table "student_attachments", :force => true do |t|
    t.integer  "batch_id"
    t.integer  "student_id"
    t.integer  "uploader_id"
    t.string   "attachment_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.boolean  "is_registered",           :default => false
    t.integer  "school_id"
  end

  add_index "student_attachments", ["school_id"], :name => "index_student_attachments_on_school_id", :limit => {"school_id"=>nil}
  add_index "student_attachments", ["student_id", "is_registered"], :name => "index_on_student_id_and_is_registered", :limit => {"is_registered"=>nil, "student_id"=>nil}
  add_index "student_attachments", ["student_id"], :name => "index_on_student_id", :limit => {"student_id"=>nil}

  create_table "student_categories", :force => true do |t|
    t.string   "name"
    t.boolean  "is_deleted", :default => false, :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "student_categories", ["school_id"], :name => "index_student_categories_on_school_id", :limit => {"school_id"=>nil}

  create_table "student_coscholastic_remark_copies", :force => true do |t|
    t.integer  "student_id"
    t.integer  "batch_id"
    t.integer  "observation_id"
    t.text     "remark"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "student_coscholastic_remark_copies", ["school_id"], :name => "index_student_coscholastic_remark_copies_on_school_id", :limit => {"school_id"=>nil}

  create_table "student_coscholastic_remarks", :force => true do |t|
    t.integer  "student_id"
    t.integer  "batch_id"
    t.integer  "observation_id"
    t.text     "remark"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "student_coscholastic_remarks", ["school_id"], :name => "index_student_coscholastic_remarks_on_school_id", :limit => {"school_id"=>nil}

  create_table "student_deletion_logs", :force => true do |t|
    t.integer  "user_id"
    t.integer  "student_id"
    t.text     "dependency_messages"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "stud_adm_no"
  end

  create_table "student_previous_datas", :force => true do |t|
    t.integer  "student_id"
    t.string   "institution"
    t.string   "year"
    t.string   "course"
    t.string   "total_mark"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "student_previous_datas", ["school_id"], :name => "index_student_previous_datas_on_school_id", :limit => {"school_id"=>nil}

  create_table "student_previous_subject_marks", :force => true do |t|
    t.integer  "student_id"
    t.string   "subject"
    t.string   "mark"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "student_previous_subject_marks", ["school_id"], :name => "index_student_previous_subject_marks_on_school_id", :limit => {"school_id"=>nil}

  create_table "student_records", :force => true do |t|
    t.integer  "student_id"
    t.integer  "batch_id"
    t.integer  "additional_field_id"
    t.text     "additional_info"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "student_records", ["additional_field_id"], :name => "index_student_records_on_additional_field_id", :limit => {"additional_field_id"=>nil}
  add_index "student_records", ["batch_id"], :name => "index_student_records_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "student_records", ["school_id"], :name => "index_student_records_on_school_id", :limit => {"school_id"=>nil}
  add_index "student_records", ["student_id"], :name => "index_student_records_on_student_id", :limit => {"student_id"=>nil}

  create_table "students", :force => true do |t|
    t.string   "admission_no"
    t.string   "class_roll_no"
    t.date     "admission_date"
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.integer  "batch_id"
    t.date     "date_of_birth"
    t.string   "gender"
    t.string   "blood_group"
    t.string   "birth_place"
    t.integer  "nationality_id"
    t.string   "language"
    t.string   "religion"
    t.integer  "student_category_id"
    t.string   "address_line1"
    t.string   "address_line2"
    t.string   "city"
    t.string   "state"
    t.string   "pin_code"
    t.integer  "country_id"
    t.string   "phone1"
    t.string   "phone2"
    t.string   "email"
    t.integer  "immediate_contact_id"
    t.boolean  "is_sms_enabled",                              :default => true
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.binary   "photo_data",              :limit => 16777215
    t.string   "status_description"
    t.boolean  "is_active",                                   :default => true
    t.boolean  "is_deleted",                                  :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "has_paid_fees",                               :default => false
    t.integer  "photo_file_size"
    t.integer  "user_id"
    t.boolean  "is_email_enabled",                            :default => true
    t.integer  "sibling_id"
    t.datetime "photo_updated_at"
    t.string   "roll_number"
    t.boolean  "has_paid_fees_for_batch",                     :default => false
    t.integer  "school_id"
    t.string   "library_card"
    t.integer  "familyid",                :limit => 8
  end

  add_index "students", ["admission_no", "school_id"], :name => "admission_no_unique_index", :unique => true, :limit => {"admission_no"=>nil, "school_id"=>nil}
  add_index "students", ["admission_no"], :name => "index_students_on_admission_no", :limit => {"admission_no"=>"10"}
  add_index "students", ["batch_id"], :name => "index_students_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "students", ["familyid"], :name => "index_students_on_familyid", :limit => {"familyid"=>nil}
  add_index "students", ["first_name", "middle_name", "last_name"], :name => "index_students_on_first_name_and_middle_name_and_last_name", :limit => {"last_name"=>"10", "first_name"=>"10", "middle_name"=>"10"}
  add_index "students", ["immediate_contact_id"], :name => "index_students_on_immediate_contact_id", :limit => {"immediate_contact_id"=>nil}
  add_index "students", ["nationality_id", "immediate_contact_id", "student_category_id"], :name => "student_data_index", :limit => {"student_category_id"=>nil, "nationality_id"=>nil, "immediate_contact_id"=>nil}
  add_index "students", ["school_id"], :name => "index_students_on_school_id", :limit => {"school_id"=>nil}
  add_index "students", ["sibling_id"], :name => "index_students_on_sibling_id", :limit => {"sibling_id"=>nil}
  add_index "students", ["user_id"], :name => "index_students_on_user_id", :limit => {"user_id"=>nil}

  create_table "students_subjects", :force => true do |t|
    t.integer  "student_id"
    t.integer  "subject_id"
    t.integer  "batch_id"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "students_subjects", ["school_id"], :name => "index_students_subjects_on_school_id", :limit => {"school_id"=>nil}
  add_index "students_subjects", ["student_id", "subject_id"], :name => "index_students_subjects_on_student_id_and_subject_id", :limit => {"student_id"=>nil, "subject_id"=>nil}

  create_table "subject_amounts", :force => true do |t|
    t.integer  "course_id"
    t.decimal  "amount",     :precision => 15, :scale => 4
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "subject_amounts", ["school_id"], :name => "index_subject_amounts_on_school_id", :limit => {"school_id"=>nil}

  create_table "subject_assessments", :force => true do |t|
    t.integer  "assessment_group_batch_id"
    t.date     "exam_date"
    t.time     "start_time"
    t.time     "end_time"
    t.integer  "subject_id"
    t.integer  "elective_group_id"
    t.decimal  "maximum_marks",             :precision => 10, :scale => 2
    t.decimal  "minimum_marks",             :precision => 10, :scale => 2
    t.boolean  "marks_added",                                              :default => false
    t.integer  "submission_status"
    t.boolean  "edited",                                                   :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "has_skill_assessments",                                    :default => false
    t.integer  "subject_skill_set_id"
    t.boolean  "mark_entry_locked",                                        :default => false
    t.boolean  "unlocked",                                                 :default => false
    t.integer  "school_id"
  end

  add_index "subject_assessments", ["assessment_group_batch_id"], :name => "index_subject_assessments_on_assessment_group_batch_id", :limit => {"assessment_group_batch_id"=>nil}
  add_index "subject_assessments", ["elective_group_id"], :name => "index_subject_assessments_on_elective_group_id", :limit => {"elective_group_id"=>nil}
  add_index "subject_assessments", ["marks_added"], :name => "index_subject_assessments_on_marks_added", :limit => {"marks_added"=>nil}
  add_index "subject_assessments", ["school_id"], :name => "index_subject_assessments_on_school_id", :limit => {"school_id"=>nil}
  add_index "subject_assessments", ["subject_id"], :name => "index_subject_assessments_on_subject_id", :limit => {"subject_id"=>nil}
  add_index "subject_assessments", ["subject_skill_set_id"], :name => "index_subject_assessments_on_subject_skill_set_id", :limit => {"subject_skill_set_id"=>nil}

  create_table "subject_attribute_assessments", :force => true do |t|
    t.integer  "assessment_group_batch_id"
    t.integer  "subject_id"
    t.integer  "batch_id"
    t.integer  "assessment_attribute_profile_id"
    t.integer  "submission_status"
    t.boolean  "marks_added",                     :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "mark_entry_locked",               :default => false
    t.boolean  "unlocked",                        :default => false
    t.integer  "school_id"
  end

  add_index "subject_attribute_assessments", ["school_id"], :name => "index_subject_attribute_assessments_on_school_id", :limit => {"school_id"=>nil}

  create_table "subject_groups", :force => true do |t|
    t.string   "name"
    t.integer  "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "priority"
    t.integer  "import_from"
    t.boolean  "calculate_final", :default => false
    t.string   "formula"
    t.integer  "previous_id"
    t.integer  "school_id"
  end

  add_index "subject_groups", ["priority"], :name => "index_subject_groups_on_priority", :limit => {"priority"=>nil}
  add_index "subject_groups", ["school_id"], :name => "index_subject_groups_on_school_id", :limit => {"school_id"=>nil}

  create_table "subject_imports", :force => true do |t|
    t.integer  "course_id"
    t.text     "parameters"
    t.text     "last_error"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "subject_imports", ["school_id"], :name => "index_subject_imports_on_school_id", :limit => {"school_id"=>nil}

  create_table "subject_leaves", :force => true do |t|
    t.integer  "student_id"
    t.date     "month_date"
    t.integer  "subject_id"
    t.integer  "employee_id"
    t.integer  "class_timing_id"
    t.string   "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "batch_id"
    t.boolean  "notification_sent"
    t.integer  "attendance_label_id"
    t.integer  "weightage"
    t.integer  "school_id"
  end

  add_index "subject_leaves", ["attendance_label_id"], :name => "index_by_attendance_label_id", :limit => {"attendance_label_id"=>nil}
  add_index "subject_leaves", ["batch_id", "month_date"], :name => "index_subject_leaves_on_batch_id_and_month_date", :limit => {"month_date"=>nil, "batch_id"=>nil}
  add_index "subject_leaves", ["month_date", "subject_id", "batch_id", "class_timing_id"], :name => "index_month_date_and_subject_id_and_batch_id_and_class_timing_id", :limit => {"month_date"=>nil, "class_timing_id"=>nil, "batch_id"=>nil, "subject_id"=>nil}
  add_index "subject_leaves", ["month_date", "subject_id", "batch_id"], :name => "index_subject_leaves_on_month_date_and_subject_id_and_batch_id", :limit => {"month_date"=>nil, "batch_id"=>nil, "subject_id"=>nil}
  add_index "subject_leaves", ["school_id"], :name => "index_subject_leaves_on_school_id", :limit => {"school_id"=>nil}
  add_index "subject_leaves", ["student_id", "batch_id"], :name => "index_subject_leaves_on_student_id_and_batch_id", :limit => {"batch_id"=>nil, "student_id"=>nil}
  add_index "subject_leaves", ["subject_id"], :name => "index_subject_leaves_on_subject_id", :limit => {"subject_id"=>nil}

  create_table "subject_leaves_teachers", :id => false, :force => true do |t|
    t.integer "employee_id"
    t.integer "subject_leave_id"
  end

  add_index "subject_leaves_teachers", ["employee_id", "subject_leave_id"], :name => "index_by_fields", :limit => {"employee_id"=>nil, "subject_leave_id"=>nil}

  create_table "subject_skill_sets", :force => true do |t|
    t.string   "name"
    t.boolean  "calculate_final"
    t.string   "formula"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "subject_skill_sets", ["school_id"], :name => "index_subject_skill_sets_on_school_id", :limit => {"school_id"=>nil}

  create_table "subject_skills", :force => true do |t|
    t.string   "name"
    t.integer  "subject_skill_set_id"
    t.boolean  "calculate_final"
    t.string   "formula"
    t.decimal  "maximum_marks",        :precision => 8, :scale => 2
    t.decimal  "minimum_marks",        :precision => 8, :scale => 2
    t.string   "grade"
    t.integer  "higher_skill_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "subject_skills", ["school_id"], :name => "index_subject_skills_on_school_id", :limit => {"school_id"=>nil}

  create_table "subjects", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.integer  "batch_id"
    t.boolean  "no_exams",                                               :default => false
    t.integer  "max_weekly_classes"
    t.integer  "elective_group_id"
    t.boolean  "is_deleted",                                             :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "credit_hours",            :precision => 15, :scale => 2
    t.boolean  "prefer_consecutive",                                     :default => false
    t.decimal  "amount",                  :precision => 15, :scale => 4
    t.boolean  "is_asl",                                                 :default => false
    t.integer  "asl_mark"
    t.boolean  "is_sixth_subject",                                       :default => false
    t.integer  "course_subject_id"
    t.integer  "priority"
    t.integer  "subject_skill_set_id"
    t.boolean  "is_activity",                                            :default => false
    t.integer  "batch_subject_group_id"
    t.boolean  "exclude_for_final_score",                                :default => false
    t.integer  "school_id"
  end

  add_index "subjects", ["batch_id", "elective_group_id", "is_deleted"], :name => "index_subjects_on_batch_id_and_elective_group_id_and_is_deleted", :limit => {"is_deleted"=>nil, "batch_id"=>nil, "elective_group_id"=>nil}
  add_index "subjects", ["batch_subject_group_id"], :name => "index_subjects_on_batch_subject_group_id", :limit => {"batch_subject_group_id"=>nil}
  add_index "subjects", ["course_subject_id"], :name => "index_subjects_on_course_subject_id", :limit => {"course_subject_id"=>nil}
  add_index "subjects", ["is_deleted", "elective_group_id"], :name => "index_on_elective_active_subject", :limit => {"is_deleted"=>nil, "elective_group_id"=>nil}
  add_index "subjects", ["priority"], :name => "index_subjects_on_priority", :limit => {"priority"=>nil}
  add_index "subjects", ["school_id"], :name => "index_subjects_on_school_id", :limit => {"school_id"=>nil}

  create_table "supplier_types", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.boolean  "is_deleted", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "supplier_types", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "suppliers", :force => true do |t|
    t.string   "name"
    t.string   "contact_no"
    t.text     "address"
    t.string   "tin_no"
    t.string   "region"
    t.text     "help_desk"
    t.boolean  "is_deleted",       :default => false
    t.integer  "supplier_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "suppliers", ["school_id"], :name => "by_school_id", :limit => {"school_id"=>nil}

  create_table "support_task_stats", :force => true do |t|
    t.integer  "owner_id"
    t.integer  "script_id"
    t.integer  "status"
    t.string   "task_type"
    t.text     "params"
    t.text     "note"
    t.text     "log"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
    t.integer  "school_id"
    t.datetime "updated_at"
  end

  add_index "taggings", ["school_id"], :name => "index_taggings_on_school_id", :limit => {"school_id"=>nil}
  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id", :limit => {"tag_id"=>nil}
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type", :limit => {"taggable_id"=>nil, "taggable_type"=>nil}

  create_table "tags", :force => true do |t|
    t.string   "name"
    t.integer  "school_id"
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "tags", ["school_id"], :name => "index_tags_on_school_id", :limit => {"school_id"=>nil}

  create_table "tally_accounts", :force => true do |t|
    t.integer  "school_id"
    t.string   "account_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tally_companies", :force => true do |t|
    t.integer  "school_id"
    t.string   "company_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tally_export_configurations", :force => true do |t|
    t.integer  "school_id"
    t.string   "config_key"
    t.string   "config_value"
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  create_table "tally_export_files", :force => true do |t|
    t.integer  "download_no",              :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.string   "export_file_file_name"
    t.string   "export_file_content_type"
    t.integer  "export_file_file_size"
    t.datetime "export_file_updated_at"
  end

  create_table "tally_export_logs", :force => true do |t|
    t.integer  "school_id"
    t.integer  "finance_transaction_id"
    t.boolean  "status"
    t.string   "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tally_export_logs", ["status"], :name => "index_tally_export_logs_on_status", :limit => {"status"=>nil}
  add_index "tally_export_logs", ["updated_at"], :name => "by_updation", :limit => {"updated_at"=>nil}

  create_table "tally_ledgers", :force => true do |t|
    t.integer  "school_id"
    t.string   "ledger_name"
    t.integer  "tally_company_id"
    t.integer  "tally_voucher_type_id"
    t.integer  "tally_account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tally_voucher_types", :force => true do |t|
    t.integer  "school_id"
    t.string   "voucher_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "task_assignees", :force => true do |t|
    t.integer  "task_id"
    t.integer  "assignee_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "task_assignees", ["school_id"], :name => "index_task_assignees_on_school_id", :limit => {"school_id"=>nil}

  create_table "task_comments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "task_id"
    t.text     "description"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "task_comments", ["school_id"], :name => "index_task_comments_on_school_id", :limit => {"school_id"=>nil}

  create_table "tasks", :force => true do |t|
    t.integer  "user_id"
    t.string   "title"
    t.text     "description"
    t.string   "status"
    t.date     "start_date"
    t.date     "due_date"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "tasks", ["school_id"], :name => "index_tasks_on_school_id", :limit => {"school_id"=>nil}

  create_table "tax_assignments", :force => true do |t|
    t.integer  "taxable_id",   :null => false
    t.string   "taxable_type", :null => false
    t.integer  "tax_slab_id",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "tax_assignments", ["school_id"], :name => "index_tax_assignments_on_school_id", :limit => {"school_id"=>nil}
  add_index "tax_assignments", ["tax_slab_id"], :name => "index_by_tax_slab_id", :limit => {"tax_slab_id"=>nil}
  add_index "tax_assignments", ["taxable_type", "taxable_id"], :name => "index_by_taxable", :limit => {"taxable_type"=>nil, "taxable_id"=>nil}

  create_table "tax_collections", :force => true do |t|
    t.integer  "taxable_entity_id",                                  :null => false
    t.string   "taxable_entity_type",                                :null => false
    t.integer  "taxable_fee_id",                                     :null => false
    t.string   "taxable_fee_type",                                   :null => false
    t.decimal  "tax_amount",          :precision => 10, :scale => 4, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "slab_id",                                            :null => false
    t.integer  "school_id"
  end

  add_index "tax_collections", ["school_id"], :name => "index_tax_collections_on_school_id", :limit => {"school_id"=>nil}
  add_index "tax_collections", ["slab_id"], :name => "index_by_slab_id", :limit => {"slab_id"=>nil}
  add_index "tax_collections", ["taxable_entity_type", "taxable_entity_id"], :name => "index_by_taxable_entity", :limit => {"taxable_entity_type"=>nil, "taxable_entity_id"=>nil}
  add_index "tax_collections", ["taxable_fee_type", "taxable_fee_id"], :name => "index_by_taxable_fee", :limit => {"taxable_fee_id"=>nil, "taxable_fee_type"=>nil}

  create_table "tax_payments", :force => true do |t|
    t.integer  "taxed_entity_id",                                                         :null => false
    t.string   "taxed_entity_type",                                                       :null => false
    t.integer  "taxed_fee_id",                                                            :null => false
    t.string   "taxed_fee_type",                                                          :null => false
    t.decimal  "tax_amount",             :precision => 10, :scale => 4
    t.integer  "finance_transaction_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_active",                                             :default => true
    t.integer  "school_id"
  end

  add_index "tax_payments", ["is_active"], :name => "by_active", :limit => {"is_active"=>nil}
  add_index "tax_payments", ["school_id"], :name => "index_tax_payments_on_school_id", :limit => {"school_id"=>nil}
  add_index "tax_payments", ["taxed_entity_type", "taxed_entity_id"], :name => "index_by_taxed_entity", :limit => {"taxed_entity_type"=>nil, "taxed_entity_id"=>nil}
  add_index "tax_payments", ["taxed_fee_type", "taxed_fee_id"], :name => "index_by_taxed_fee", :limit => {"taxed_fee_id"=>nil, "taxed_fee_type"=>nil}

  create_table "tax_slabs", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.decimal  "rate",        :precision => 10, :scale => 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "tax_slabs", ["school_id"], :name => "index_tax_slabs_on_school_id", :limit => {"school_id"=>nil}

  create_table "tc_template_fields", :force => true do |t|
    t.string   "type"
    t.integer  "school_id"
    t.text     "field_name"
    t.text     "field_info"
    t.integer  "priority"
    t.integer  "parent_field_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tc_template_fields", ["type"], :name => "index_tc_template_fields_on_type", :limit => {"type"=>nil}

  create_table "tc_template_fields_tc_template_versions", :id => false, :force => true do |t|
    t.integer "tc_template_field_id"
    t.integer "tc_template_version_id"
  end

  add_index "tc_template_fields_tc_template_versions", ["tc_template_field_id"], :name => "index_tc_template_field_id", :limit => {"tc_template_field_id"=>nil}
  add_index "tc_template_fields_tc_template_versions", ["tc_template_version_id"], :name => "index_tc_template_version_id", :limit => {"tc_template_version_id"=>nil}

  create_table "tc_template_records", :force => true do |t|
    t.integer  "student_id"
    t.integer  "school_id"
    t.string   "prefix"
    t.string   "certificate_number"
    t.date     "date_of_issue"
    t.text     "record_data"
    t.integer  "tc_template_version_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tc_template_records", ["student_id"], :name => "tc_template_student_unique_index", :unique => true, :limit => {"student_id"=>nil}

  create_table "tc_template_versions", :force => true do |t|
    t.boolean  "is_active",            :default => true
    t.integer  "school_id"
    t.float    "header_space"
    t.integer  "footer_space"
    t.boolean  "header_settings_edit", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "font_value",           :default => "normal"
  end

  add_index "tc_template_versions", ["is_active"], :name => "index_tc_template_versions_on_is_active", :limit => {"is_active"=>nil}

  create_table "teacher_timetable_entries", :id => false, :force => true do |t|
    t.integer "employee_id"
    t.integer "timetable_entry_id"
  end

  add_index "teacher_timetable_entries", ["employee_id", "timetable_entry_id"], :name => "index_by_fields", :limit => {"timetable_entry_id"=>nil, "employee_id"=>nil}
  add_index "teacher_timetable_entries", ["timetable_entry_id"], :name => "index_on_timetable_entry_id", :limit => {"timetable_entry_id"=>nil}

  create_table "template_custom_fields", :force => true do |t|
    t.string   "name"
    t.string   "key"
    t.integer  "corresponding_template_id"
    t.string   "corresponding_template_type"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "template_custom_fields", ["school_id"], :name => "index_template_custom_fields_on_school_id", :limit => {"school_id"=>nil}

  create_table "time_table_class_timing_sets", :force => true do |t|
    t.integer  "batch_id"
    t.integer  "time_table_class_timing_id"
    t.integer  "class_timing_set_id"
    t.integer  "weekday_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "time_table_class_timing_sets", ["batch_id"], :name => "index_time_table_class_timing_sets_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "time_table_class_timing_sets", ["school_id"], :name => "index_time_table_class_timing_sets_on_school_id", :limit => {"school_id"=>nil}
  add_index "time_table_class_timing_sets", ["time_table_class_timing_id", "batch_id", "class_timing_set_id", "weekday_id"], :name => "ttctctsw_index", :limit => {"time_table_class_timing_id"=>nil, "batch_id"=>nil, "weekday_id"=>nil, "class_timing_set_id"=>nil}
  add_index "time_table_class_timing_sets", ["time_table_class_timing_id"], :name => "index_time_table_class_timing_sets_on_time_table_class_timing_id", :limit => {"time_table_class_timing_id"=>nil}

  create_table "time_table_class_timings", :force => true do |t|
    t.integer  "batch_id"
    t.integer  "timetable_id"
    t.integer  "class_timing_set_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "time_table_class_timings", ["batch_id"], :name => "index_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "time_table_class_timings", ["school_id"], :name => "index_time_table_class_timings_on_school_id", :limit => {"school_id"=>nil}
  add_index "time_table_class_timings", ["timetable_id", "batch_id"], :name => "timetable_id_and_batch_id_index", :limit => {"batch_id"=>nil, "timetable_id"=>nil}

  create_table "time_table_weekdays", :force => true do |t|
    t.integer  "batch_id"
    t.integer  "timetable_id"
    t.integer  "weekday_set_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "time_table_weekdays", ["batch_id", "timetable_id"], :name => "batch_timetable_index", :limit => {"batch_id"=>nil, "timetable_id"=>nil}
  add_index "time_table_weekdays", ["school_id"], :name => "index_time_table_weekdays_on_school_id", :limit => {"school_id"=>nil}

  create_table "time_zones", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.string   "difference_type"
    t.integer  "time_difference"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "timetable_entries", :force => true do |t|
    t.integer  "batch_id"
    t.integer  "weekday_id"
    t.integer  "class_timing_id"
    t.integer  "subject_id"
    t.integer  "employee_id"
    t.integer  "timetable_id"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "entry_type"
    t.integer  "entry_id"
    t.boolean  "mode",            :default => false
    t.integer  "school_id"
  end

  add_index "timetable_entries", ["class_timing_id"], :name => "index_timetable_entries_on_class_timing_id", :limit => {"class_timing_id"=>nil}
  add_index "timetable_entries", ["entry_type", "entry_id"], :name => "timetable_entries_polymorphic_entry_index", :limit => {"entry_type"=>nil, "entry_id"=>nil}
  add_index "timetable_entries", ["school_id"], :name => "index_timetable_entries_on_school_id", :limit => {"school_id"=>nil}
  add_index "timetable_entries", ["timetable_id"], :name => "index_timetable_entries_on_timetable_id", :limit => {"timetable_id"=>nil}

  create_table "timetable_swaps", :force => true do |t|
    t.date     "date"
    t.integer  "timetable_entry_id"
    t.integer  "employee_id"
    t.integer  "subject_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_cancelled",       :default => false
    t.integer  "school_id"
  end

  add_index "timetable_swaps", ["is_cancelled"], :name => "index_on_is_cancelled", :limit => {"is_cancelled"=>nil}
  add_index "timetable_swaps", ["school_id"], :name => "index_timetable_swaps_on_school_id", :limit => {"school_id"=>nil}

  create_table "timetables", :force => true do |t|
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "is_active",                                    :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "timetable_status",         :limit => 1,        :default => 0
    t.text     "timetable_summary",        :limit => 16777215
    t.integer  "timetable_summary_status", :limit => 1,        :default => 1
    t.integer  "school_id"
  end

  add_index "timetables", ["end_date"], :name => "index_timetables_on_end_date", :limit => {"end_date"=>nil}
  add_index "timetables", ["school_id"], :name => "index_timetables_on_school_id", :limit => {"school_id"=>nil}
  add_index "timetables", ["start_date", "end_date"], :name => "by_start_and_end", :limit => {"start_date"=>nil, "end_date"=>nil}
  add_index "timetables", ["start_date"], :name => "index_timetables_on_start_date", :limit => {"start_date"=>nil}

  create_table "transaction_receipts", :force => true do |t|
    t.string   "receipt_sequence"
    t.string   "receipt_number",        :null => false
    t.integer  "receipt_number_set_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ef_receipt_number"
  end

  add_index "transaction_receipts", ["ef_receipt_number"], :name => "index_transaction_receipts_on_ef_receipt_number", :limit => {"ef_receipt_number"=>nil}
  add_index "transaction_receipts", ["receipt_number_set_id"], :name => "index_by_receipt_number_set", :limit => {"receipt_number_set_id"=>nil}
  add_index "transaction_receipts", ["receipt_sequence", "receipt_number", "school_id"], :name => "school_receipt_uniqueness", :unique => true, :limit => {"receipt_number"=>nil, "receipt_sequence"=>nil, "school_id"=>nil}
  add_index "transaction_receipts", ["school_id"], :name => "index_transaction_receipts_on_school_id", :limit => {"school_id"=>nil}

  create_table "transaction_report_syncs", :force => true do |t|
    t.integer  "transaction_id",                      :null => false
    t.string   "transaction_type",                    :null => false
    t.boolean  "sync_status",      :default => false
    t.boolean  "is_income",                           :null => false
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "last_error"
    t.datetime "failed_at"
  end

  add_index "transaction_report_syncs", ["school_id"], :name => "index_transaction_report_syncs_on_school_id", :limit => {"school_id"=>nil}
  add_index "transaction_report_syncs", ["transaction_id", "sync_status"], :name => "by_tran_id_and_sync_status", :limit => {"sync_status"=>nil, "transaction_id"=>nil}
  add_index "transaction_report_syncs", ["transaction_id", "transaction_type"], :name => "by_transaction", :unique => true, :limit => {"transaction_type"=>nil, "transaction_id"=>nil}

  create_table "transport_additional_details", :force => true do |t|
    t.integer  "linkable_id"
    t.string   "linkable_type"
    t.integer  "transport_additional_field_id"
    t.string   "additional_info"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transport_additional_fields", :force => true do |t|
    t.string   "name"
    t.boolean  "is_mandatory"
    t.string   "input_type"
    t.integer  "priority"
    t.boolean  "is_active"
    t.integer  "school_id"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transport_attendance_days", :force => true do |t|
    t.date     "attendance_date"
    t.integer  "route_type"
    t.integer  "route_id"
    t.string   "receiver_type"
    t.boolean  "all_present",     :default => true
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transport_attendances", :force => true do |t|
    t.date     "attendance_date"
    t.integer  "receiver_id"
    t.string   "receiver_type"
    t.integer  "route_type"
    t.integer  "route_id"
    t.datetime "entering"
    t.datetime "leaving"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "transport_attendances", ["receiver_type", "receiver_id"], :name => "index_on_r_type_id", :limit => {"receiver_id"=>nil, "receiver_type"=>nil}
  add_index "transport_attendances", ["route_type", "route_id"], :name => "index_on_route", :limit => {"route_type"=>nil, "route_id"=>nil}
  add_index "transport_attendances", ["school_id"], :name => "index_transport_attendances_on_school_id", :limit => {"school_id"=>nil}

  create_table "transport_fee_collection_assignments", :force => true do |t|
    t.integer  "transport_fee_collection_id"
    t.string   "assignee_type"
    t.integer  "assignee_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "transport_fee_collection_assignments", ["assignee_id", "assignee_type"], :name => "index_by_assignee", :limit => {"assignee_type"=>nil, "assignee_id"=>nil}
  add_index "transport_fee_collection_assignments", ["school_id"], :name => "index_by_school_id", :limit => {"school_id"=>nil}
  add_index "transport_fee_collection_assignments", ["transport_fee_collection_id"], :name => "index_by_tf_collection_id", :limit => {"transport_fee_collection_id"=>nil}

  create_table "transport_fee_collection_batches", :force => true do |t|
    t.integer  "transport_fee_collection_id"
    t.integer  "batch_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transport_fee_collections", :force => true do |t|
    t.string   "name"
    t.integer  "batch_id"
    t.date     "start_date"
    t.date     "end_date"
    t.date     "due_date"
    t.boolean  "is_deleted",               :default => false, :null => false
    t.integer  "school_id"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.boolean  "tax_enabled",              :default => false
    t.boolean  "invoice_enabled",          :default => false
    t.integer  "fine_id"
    t.integer  "fee_account_id"
    t.integer  "financial_year_id"
    t.integer  "master_fee_particular_id"
  end

  add_index "transport_fee_collections", ["batch_id"], :name => "index_transport_fee_collections_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "transport_fee_collections", ["due_date"], :name => "index_transport_fee_collections_on_due_date", :limit => {"due_date"=>nil}
  add_index "transport_fee_collections", ["financial_year_id"], :name => "index_by_fyid", :limit => {"financial_year_id"=>nil}
  add_index "transport_fee_collections", ["is_deleted", "due_date"], :name => "is_deleted_and_due_date", :limit => {"due_date"=>nil, "is_deleted"=>nil}
  add_index "transport_fee_collections", ["is_deleted"], :name => "index_transport_fee_collections_on_is_deleted", :limit => {"is_deleted"=>nil}
  add_index "transport_fee_collections", ["master_fee_particular_id"], :name => "by_master_particular_id", :limit => {"master_fee_particular_id"=>nil}
  add_index "transport_fee_collections", ["school_id"], :name => "index_transport_fee_collections_on_school_id", :limit => {"school_id"=>nil}

  create_table "transport_fee_discounts", :force => true do |t|
    t.string   "name"
    t.integer  "transport_fee_id"
    t.decimal  "discount",               :precision => 15, :scale => 2
    t.boolean  "is_amount",                                             :default => false
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "multi_fee_discount_id"
    t.integer  "master_fee_discount_id"
    t.integer  "finance_transaction_id"
  end

  add_index "transport_fee_discounts", ["master_fee_discount_id"], :name => "index_by_master_fee_discount", :limit => {"master_fee_discount_id"=>nil}
  add_index "transport_fee_discounts", ["multi_fee_discount_id"], :name => "by_multi_fee_discount", :limit => {"multi_fee_discount_id"=>nil}

  create_table "transport_fee_finance_transactions", :force => true do |t|
    t.decimal  "transaction_balance",    :precision => 15, :scale => 4
    t.decimal  "transaction_amount",     :precision => 15, :scale => 4
    t.integer  "finance_transaction_id"
    t.integer  "parent_id"
    t.integer  "transport_fee_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "transport_fee_finance_transactions", ["finance_transaction_id"], :name => "index_by_finance_transaction_id", :limit => {"finance_transaction_id"=>nil}

  create_table "transport_fees", :force => true do |t|
    t.integer  "receiver_id"
    t.decimal  "bus_fare",                    :precision => 15, :scale => 4
    t.integer  "transaction_id"
    t.integer  "transport_fee_collection_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "receiver_type"
    t.integer  "school_id"
    t.boolean  "is_active",                                                  :default => true
    t.integer  "groupable_id"
    t.string   "groupable_type"
    t.decimal  "balance",                     :precision => 15, :scale => 4
    t.boolean  "tax_enabled",                                                :default => false
    t.decimal  "tax_amount",                  :precision => 15, :scale => 4
    t.boolean  "is_paid",                                                    :default => false
    t.decimal  "balance_fine",                :precision => 15, :scale => 2
    t.boolean  "is_fine_waiver",                                             :default => false
  end

  add_index "transport_fees", ["bus_fare"], :name => "index_transport_fees_on_bus_fare", :limit => {"bus_fare"=>nil}
  add_index "transport_fees", ["groupable_id", "groupable_type"], :name => "index_transport_fees_on_groupable_id_and_groupable_type", :limit => {"groupable_id"=>nil, "groupable_type"=>nil}
  add_index "transport_fees", ["receiver_id", "receiver_type"], :name => "index_transport_fees_on_receiver_id_and_receiver_type", :limit => {"receiver_id"=>nil, "receiver_type"=>nil}
  add_index "transport_fees", ["receiver_id", "transaction_id"], :name => "indices_on_transactions", :limit => {"receiver_id"=>nil, "transaction_id"=>nil}
  add_index "transport_fees", ["school_id"], :name => "index_transport_fees_on_school_id", :limit => {"school_id"=>nil}
  add_index "transport_fees", ["transport_fee_collection_id"], :name => "transport_fee_collection_id", :limit => {"transport_fee_collection_id"=>nil}

  create_table "transport_gps_settings", :force => true do |t|
    t.string   "client_id"
    t.string   "client_secret"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "vendor_name"
    t.string   "vendor_code"
    t.integer  "integration_id"
    t.string   "integration_vector"
    t.boolean  "sync_applicable"
  end

  create_table "transport_gps_syncs", :force => true do |t|
    t.string   "status"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "last_error",   :limit => 2147483647
  end

  create_table "transport_imports", :force => true do |t|
    t.integer  "import_from_id"
    t.integer  "import_to_id"
    t.text     "imports"
    t.text     "completed_imports"
    t.integer  "status"
    t.text     "last_error"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "transport_imports", ["import_from_id"], :name => "index_transport_imports_on_import_from_id", :limit => {"import_from_id"=>nil}
  add_index "transport_imports", ["import_to_id"], :name => "index_transport_imports_on_import_to_id", :limit => {"import_to_id"=>nil}
  add_index "transport_imports", ["school_id"], :name => "index_transport_imports_on_school_id", :limit => {"school_id"=>nil}

  create_table "transport_old_datas", :force => true do |t|
    t.string   "model_name"
    t.string   "model_id"
    t.text     "data_rows"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transport_passenger_imports", :force => true do |t|
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.integer  "status",                                        :default => 0
    t.integer  "academic_year_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "last_message",            :limit => 2147483647
  end

  add_index "transport_passenger_imports", ["academic_year_id"], :name => "index_transport_passenger_imports_on_academic_year_id", :limit => {"academic_year_id"=>nil}
  add_index "transport_passenger_imports", ["school_id"], :name => "index_transport_passenger_imports_on_school_id", :limit => {"school_id"=>nil}

  create_table "transport_transaction_discounts", :force => true do |t|
    t.integer  "finance_transaction_id",                                                     :null => false
    t.integer  "transport_fee_discount_id",                                                  :null => false
    t.decimal  "discount_amount",           :precision => 15, :scale => 4, :default => 0.0
    t.integer  "school_id",                                                                  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_active",                                                :default => true
  end

  add_index "transport_transaction_discounts", ["finance_transaction_id"], :name => "index_by_transaction_id", :limit => {"finance_transaction_id"=>nil}
  add_index "transport_transaction_discounts", ["is_active"], :name => "index_by_active", :limit => {"is_active"=>nil}
  add_index "transport_transaction_discounts", ["school_id"], :name => "index_by_school_id", :limit => {"school_id"=>nil}
  add_index "transport_transaction_discounts", ["transport_fee_discount_id"], :name => "index_by_discount_id", :limit => {"transport_fee_discount_id"=>nil}

  create_table "transports", :force => true do |t|
    t.integer  "receiver_id"
    t.integer  "vehicle_id"
    t.integer  "route_id"
    t.decimal  "bus_fare",         :precision => 15, :scale => 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "receiver_type"
    t.integer  "school_id"
    t.boolean  "auto_update_fare",                                :default => true
    t.integer  "academic_year_id"
    t.integer  "mode"
    t.integer  "pickup_route_id"
    t.integer  "pickup_stop_id"
    t.integer  "drop_route_id"
    t.integer  "drop_stop_id"
    t.date     "applied_from"
    t.boolean  "remove_fare",                                     :default => false
  end

  add_index "transports", ["academic_year_id"], :name => "index_transports_on_academic_year_id", :limit => {"academic_year_id"=>nil}
  add_index "transports", ["drop_route_id"], :name => "index_transports_on_drop_route_id", :limit => {"drop_route_id"=>nil}
  add_index "transports", ["drop_stop_id"], :name => "index_transports_on_drop_stop_id", :limit => {"drop_stop_id"=>nil}
  add_index "transports", ["pickup_route_id", "drop_route_id"], :name => "index_on_route", :limit => {"drop_route_id"=>nil, "pickup_route_id"=>nil}
  add_index "transports", ["pickup_route_id"], :name => "index_transports_on_pickup_route_id", :limit => {"pickup_route_id"=>nil}
  add_index "transports", ["pickup_stop_id"], :name => "index_transports_on_pickup_stop_id", :limit => {"pickup_stop_id"=>nil}
  add_index "transports", ["receiver_type", "receiver_id"], :name => "index_on_r_type_id", :limit => {"receiver_id"=>nil, "receiver_type"=>nil}
  add_index "transports", ["route_id"], :name => "index_transports_on_route_id", :limit => {"route_id"=>nil}
  add_index "transports", ["school_id"], :name => "index_transports_on_school_id", :limit => {"school_id"=>nil}
  add_index "transports", ["vehicle_id"], :name => "index_transports_on_vehicle_id", :limit => {"vehicle_id"=>nil}

  create_table "upscale_scores", :force => true do |t|
    t.integer  "student_id"
    t.integer  "batch_id"
    t.integer  "subject_id"
    t.string   "upscaled_grade"
    t.string   "previous_grade"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "upscale_scores", ["school_id"], :name => "index_upscale_scores_on_school_id", :limit => {"school_id"=>nil}

  create_table "user_events", :force => true do |t|
    t.integer  "event_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "user_events", ["school_id"], :name => "index_user_events_on_school_id", :limit => {"school_id"=>nil}
  add_index "user_events", ["user_id"], :name => "index_user_events_on_user_id", :limit => {"user_id"=>nil}

  create_table "user_groups", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "status",      :default => false
    t.text     "all_members"
    t.integer  "school_id"
  end

  add_index "user_groups", ["school_id"], :name => "index_user_groups_on_school_id", :limit => {"school_id"=>nil}

  create_table "user_groups_users", :force => true do |t|
    t.integer "user_group_id"
    t.integer "user_id"
    t.integer "member_id"
    t.string  "member_type"
    t.string  "target_type"
    t.integer "school_id"
  end

  add_index "user_groups_users", ["member_type", "member_id"], :name => "index_user_groups_users_on_member_type_and_member_id", :limit => {"member_type"=>nil, "member_id"=>nil}
  add_index "user_groups_users", ["school_id"], :name => "index_user_groups_users_on_school_id", :limit => {"school_id"=>nil}
  add_index "user_groups_users", ["user_group_id", "target_type"], :name => "index_user_groups_users_on_user_group_id_and_target_type", :limit => {"user_group_id"=>nil, "target_type"=>nil}
  add_index "user_groups_users", ["user_group_id", "user_id"], :name => "index_user_groups_users_on_user_group_id_and_user_id", :limit => {"user_group_id"=>nil, "user_id"=>nil}

  create_table "user_menu_links", :force => true do |t|
    t.integer  "user_id"
    t.integer  "menu_link_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "user_menu_links", ["menu_link_id", "user_id"], :name => "on_user_and_link", :limit => {"user_id"=>nil, "menu_link_id"=>nil}
  add_index "user_menu_links", ["school_id"], :name => "index_user_menu_links_on_school_id", :limit => {"school_id"=>nil}

  create_table "user_palettes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "palette_id"
    t.integer  "position"
    t.boolean  "is_minimized",  :default => false
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "column_number"
  end

  add_index "user_palettes", ["school_id"], :name => "index_user_palettes_on_school_id", :limit => {"school_id"=>nil}
  add_index "user_palettes", ["user_id", "palette_id"], :name => "index_user_palettes_on_user_id_and_palette_id", :limit => {"palette_id"=>nil, "user_id"=>nil}

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.boolean  "admin"
    t.boolean  "student"
    t.boolean  "employee"
    t.string   "hashed_password"
    t.string   "salt"
    t.string   "reset_password_code"
    t.datetime "reset_password_code_until"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "parent"
    t.boolean  "is_first_login"
    t.boolean  "is_deleted",                :default => false
    t.integer  "school_id"
    t.boolean  "is_blocked",                :default => false
    t.boolean  "general_admin",             :default => false
  end

  add_index "users", ["admin"], :name => "index_users_on_admin", :limit => {"admin"=>nil}
  add_index "users", ["employee"], :name => "index_users_on_employee", :limit => {"employee"=>nil}
  add_index "users", ["is_deleted"], :name => "index_users_on_is_deleted", :limit => {"is_deleted"=>nil}
  add_index "users", ["parent"], :name => "index_users_on_parent", :limit => {"parent"=>nil}
  add_index "users", ["school_id"], :name => "index_users_on_school_id", :limit => {"school_id"=>nil}
  add_index "users", ["student"], :name => "index_users_on_student", :limit => {"student"=>nil}
  add_index "users", ["username", "school_id"], :name => "username_unique_index", :unique => true, :limit => {"username"=>nil, "school_id"=>nil}
  add_index "users", ["username"], :name => "index_users_on_username", :limit => {"username"=>"10"}

  create_table "vehicle_additional_field_options", :force => true do |t|
    t.string   "field_option"
    t.integer  "vehicle_additional_field_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "vehicle_certificates", :force => true do |t|
    t.integer  "certificate_type_id"
    t.string   "certificate_no"
    t.date     "date_of_issue"
    t.date     "date_of_expiry"
    t.integer  "vehicle_id"
    t.string   "certificate_file_name"
    t.string   "certificate_content_type"
    t.integer  "certificate_file_size"
    t.datetime "certificate_updated_at"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vehicle_certificates", ["certificate_type_id"], :name => "index_vehicle_certificates_on_certificate_type_id", :limit => {"certificate_type_id"=>nil}
  add_index "vehicle_certificates", ["school_id"], :name => "index_vehicle_certificates_on_school_id", :limit => {"school_id"=>nil}
  add_index "vehicle_certificates", ["vehicle_id"], :name => "index_vehicle_certificates_on_vehicle_id", :limit => {"vehicle_id"=>nil}

  create_table "vehicle_maintenance_attachments", :force => true do |t|
    t.integer  "vehicle_maintenance_id"
    t.string   "name"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  create_table "vehicle_maintenances", :force => true do |t|
    t.integer  "vehicle_id"
    t.string   "name"
    t.text     "notes"
    t.date     "maintenance_date"
    t.date     "next_maintenance_date"
    t.decimal  "amount",                :precision => 15, :scale => 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  create_table "vehicle_stops", :force => true do |t|
    t.integer  "academic_year_id"
    t.string   "name"
    t.string   "landmark"
    t.decimal  "latitude",         :precision => 10, :scale => 6
    t.decimal  "longitude",        :precision => 10, :scale => 6
    t.boolean  "is_active",                                       :default => true
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vehicle_stops", ["academic_year_id"], :name => "index_vehicle_stops_on_academic_year_id", :limit => {"academic_year_id"=>nil}
  add_index "vehicle_stops", ["is_active", "academic_year_id"], :name => "index_vehicle_stops_on_is_active_and_academic_year_id", :limit => {"is_active"=>nil, "academic_year_id"=>nil}
  add_index "vehicle_stops", ["school_id"], :name => "index_vehicle_stops_on_school_id", :limit => {"school_id"=>nil}

  create_table "vehicles", :force => true do |t|
    t.string   "vehicle_no"
    t.integer  "main_route_id"
    t.integer  "no_of_seats"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.integer  "academic_year_id"
    t.integer  "vehicle_type"
    t.string   "vehicle_model"
    t.string   "gps_number"
    t.boolean  "gps_enabled",      :default => false
  end

  add_index "vehicles", ["academic_year_id"], :name => "index_vehicles_on_academic_year_id", :limit => {"academic_year_id"=>nil}
  add_index "vehicles", ["school_id"], :name => "index_vehicles_on_school_id", :limit => {"school_id"=>nil}
  add_index "vehicles", ["status"], :name => "index_vehicles_on_status", :limit => {"status"=>nil}

  create_table "wardens", :force => true do |t|
    t.integer  "hostel_id"
    t.integer  "employee_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "wardens", ["school_id"], :name => "index_wardens_on_school_id", :limit => {"school_id"=>nil}

  create_table "weekday_sets", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_common",  :default => false
    t.integer  "school_id"
  end

  add_index "weekday_sets", ["school_id"], :name => "index_weekday_sets_on_school_id", :limit => {"school_id"=>nil}

  create_table "weekday_sets_weekdays", :force => true do |t|
    t.integer  "weekday_id"
    t.integer  "weekday_set_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
  end

  add_index "weekday_sets_weekdays", ["school_id"], :name => "index_weekday_sets_weekdays_on_school_id", :limit => {"school_id"=>nil}
  add_index "weekday_sets_weekdays", ["weekday_set_id"], :name => "index_weekday_sets_weekdays_on_weekday_set_id", :limit => {"weekday_set_id"=>nil}

  create_table "weekdays", :force => true do |t|
    t.integer  "batch_id"
    t.string   "weekday"
    t.string   "name"
    t.integer  "sort_order"
    t.integer  "day_of_week"
    t.boolean  "is_deleted",  :default => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "school_id"
  end

  add_index "weekdays", ["batch_id"], :name => "index_weekdays_on_batch_id", :limit => {"batch_id"=>nil}
  add_index "weekdays", ["school_id"], :name => "index_weekdays_on_school_id", :limit => {"school_id"=>nil}

end
