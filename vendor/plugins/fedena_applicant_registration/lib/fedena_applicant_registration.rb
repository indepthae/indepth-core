require 'dispatcher'
require "list"

module FedenaApplicantRegistration
  def self.attach_overrides
    ActiveRecord::Base.instance_eval { include ActiveRecord::Acts::List }
    Dispatcher.to_prepare :fedena_applicant_registration do
      ::Course.instance_eval { has_one :registration_course }
      FinanceController.send(:include,FedenaApplicantRegistration::ApplicantRegistrationIncomeDetails)
      ::FinanceTransaction.instance_eval { include FinanceModelExtension }
      ::FinancialYear.instance_eval { has_many :registration_courses }
      ::MasterFeeParticular.instance_eval {
        named_scope :registration_course, :conditions => {:particular_type => "RegistrationCourse"}
      }
    end
  end

  def self.csv_export_list
    return ["applicant_registration","search_by_registration"]
  end

  def self.csv_export_data(report_type,params)
    case report_type
    when "applicant_registration"
      data = Applicant.applicant_registration_data(params)
    when "search_by_registration"
      data = Applicant.search_by_registration_data(params)
    end
  end

  module FinanceModelExtension
    def self.included(base)
      base.instance_eval do
        named_scope :account_active,
                    :joins => "INNER JOIN finance_transaction_receipt_records ftrr
                                       ON ftrr.finance_transaction_id = finance_transactions.id
                                LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
                    :conditions => "(ftrr.fee_account_id IS NULL OR
                                     (ftrr.fee_account_id IS NOT NULL AND fa.is_deleted = false))"
      end
    end
  end

  module ApplicantRegistrationIncomeDetails
    def self.included(base)
      base.alias_method_chain :income_details,:applicant_registration
    end
    def income_details_with_applicant_registration
      if date_format_check
        if FedenaPlugin.can_access_plugin?("fedena_applicant_registration")
          @target_action = "income_details"

          if validate_date

            filter_by_account, account_id = account_filter
            joins = "LEFT JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
                     LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
            cond = "(fa.id IS NULL OR fa.is_deleted = false)"
            if filter_by_account
              filter_conditions = "AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
              filter_values = [account_id]
            else
              filter_conditions = ""
              filter_values = []
            end

            if params[:id].present?
              @income_category = FinanceTransactionCategory.find(params[:id])
              @incomes = @income_category.finance_transactions.find(:all, :joins => joins,
                :conditions => ["#{cond} AND (transaction_date BETWEEN ? AND ?) #{filter_conditions}",
                  @start_date, @end_date ] + filter_values )
            else
              @income_category = FinanceTransactionCategory.find_by_name('Applicant Registration')

              @grand_total = @income_category.finance_transactions.all(:select => "amount", :joins => joins,
                :conditions => ["(transaction_date BETWEEN ? AND ?) #{filter_conditions}",
                  @start_date, @end_date ] + filter_values).map {|x| x.amount.to_f }.sum

              @transactions = @income_category.finance_transactions.paginate(:page => params[:page],
                :joins => "INNER JOIN applicants on finance_transactions.payee_id = applicants.id #{joins}
                           INNER JOIN registration_courses on registration_courses.id = applicants.registration_course_id",
                :select => "finance_transactions.*, registration_courses.course_id AS c_id,
                            applicants.reg_no AS applicant_reg_no", :per_page => 10, :include => :transaction_receipt,
                :conditions => ["#{cond} AND (finance_transactions.transaction_date BETWEEN ? AND ?) #{filter_conditions}",
                  @start_date, @end_date ] + filter_values)

              @course_ids = @transactions.group_by(&:c_id)
            end

            if request.xhr?
              render(:update) do|page|
                page.replace_html "fee_report_div", :partial=>"finance_income_details/income_details_partial"
              end
            elsif @income_category.name == 'Applicant Registration'
              render  "finance_income_details/income_details"
            else
              render  "finance/income_details"
            end
          else
            render_date_error_partial
          end
        else
          income_details_without_applicant_registration
        end
      end
    end
  end

  class ApplicantMail < Struct.new(:applicant_full_name, :email, :reg_no, :reg_course_name, :status_name, :school_details, :hostname)
    def perform
      ApplicantNotifier.deliver_send_update_notification(applicant_full_name, email, reg_no, reg_course_name, status_name, school_details, hostname)
    end
  end

  class ApplicantMessageMail < Struct.new(:email_ids, :email_subject, :email_content, :hostname, :school_details)
    def perform
      email_ids.each do |email_id|
        ApplicantMessageNotifier.deliver_send_message_notification(email_id, email_subject, email_content, hostname, school_details)
      end
    end
  end
end
