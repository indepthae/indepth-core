#Copyright 2010 Foradian Technologies Private Limited
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing,
#software distributed under the License is distributed on an
#"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#KIND, either express or implied.  See the License for the
#specific language governing permissions and limitations
#under the License.
class LibraryController < ApplicationController
  before_filter :login_required
  filter_access_to :employee_library_details,:attribute_check => true ,:load_method => lambda {Employee.find(params[:id]).user}
  filter_access_to :all
  before_filter :protect_other_student_data, :only =>[:student_library_details]


  def index

  end

  def search_book
    @book_search = []
    @book_search << ["#{t('barcode')}",'barcode']
    @book_search << ["#{t('book_number')}",'Book Number']
    @book_search << ["#{t('title')}",'title']
    @book_search << ["#{t('tag')}",'tag']
    @book_search << ["#{t('author')}",'author']
    BookAdditionalField.active.map{|a|[a.name,a.id]}.each {|a| @book_search << a }   
  end

  def search_result
    if request.get?
      page_not_found
      return
    end
    if params[:search][:search_by] == 'tag'
      @books = Book.find_tagged_with(params[:search][:name]).paginate( :page => params[:page], :per_page => 20) if params[:search][:name].length>=3      
    elsif params[:search][:search_by] == 'title'
      @books = Book.paginate(:conditions=>['books.title LIKE ?',"%#{params[:search][:name]}%"] ,:per_page=>20,:page=>params[:page]) if params[:search][:name].length>=3      
    elsif params[:search][:search_by] == 'author'
      @books = Book.paginate(:conditions=>['books.author LIKE ?',"%#{params[:search][:name]}%"] ,:per_page=>20,:page=>params[:page]) if params[:search][:name].length>=3
    elsif params[:search][:search_by] == 'barcode'      
      @books = Book.paginate(:conditions=>['books.barcode LIKE ?',"%#{params[:search][:name]}%"] ,:per_page=>20,:page=>params[:page]) if params[:search][:name].length>=3
    elsif !['tag','title','author','barcode','Book Number'].include? params[:search][:search_by]
      if params[:search][:name].present?        
        @book_ids = BookAdditionalDetail.all(:conditions=>['book_additional_details.additional_info LIKE ? and book_additional_details.book_additional_field_id = ?',"%#{params[:search][:name]}%",params[:search][:search_by]]).collect(&:book_id) if params[:search][:search_by].present?
      else
        @book_ids = BookAdditionalDetail.find_all_by_book_additional_field_id(params[:search][:search_by]).collect(&:book_id) if params[:search][:search_by].present?        
      end
      @books = Book.find(@book_ids).paginate(:per_page => 20, :page => params[:page]) if @book_ids.present?
    else      
      if params[:search][:name].length>=3        
        @books = Book.paginate(:conditions=>['books.book_number LIKE ?',"%#{params[:search][:name]}%"] ,:per_page=>20,:page=>params[:page])              
        #@books = Book.paginate(:conditions=>['books.book_number LIKE ?',"%#{params[:search][:name]}%"] ,:per_page=>20,:page=>params[:page])        
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html 'book-list', :partial => 'book_list'
      end
    end
  end

  def availabilty
    render :partial=>'availability'
  end

  def card_setting

  end

  def show_setting
    @course = Course.find(params[:course_name])
    @card_setting = LibraryCardSetting.find_all_by_course_id(@course.id)
    render(:update) do |page|
      page.replace_html 'card_setting', :partial=>'library_card_setting'
    end
  end

  def add_new_setting
    @setting = LibraryCardSetting.new
    @course = Course.find params[:id] if request.xhr? and params[:id]
    @student_categories = StudentCategory.active
    respond_to do |format|
      format.js { render :action => 'new' }
    end
  end

  def create_setting
    @library_setting = LibraryCardSetting.new(params[:library_card_setting])
    respond_to do |format|
      if  @library_setting.save
        @course = Course.find(@library_setting.course_id)
        @card_setting = LibraryCardSetting.find_all_by_course_id(@course.id)
        format.js { render :action => 'create' }

      else
        @error = true
        format.html { render :action => "new" }
        format.js { render :action => 'create' }
      end
    end
  end

  def edit_card_setting
    @setting = LibraryCardSetting.find(params[:id])
    @course = Course.find @setting.course_id
    @student_categories = StudentCategory.active
    respond_to do |format|
      format.js { render :action => 'edit' }
    end
  end

  def update_card_setting
    @setting = LibraryCardSetting.find(params[:id])
    respond_to do |format|
      if @setting.update_attributes(params[:library_card_setting])
        @course = Course.find(@setting.course_id)
        @card_setting = LibraryCardSetting.find_all_by_course_id(@course.id)
        format.js { render :action => 'update' }
      else
        @error = true
        format.html { render :action => "edit" }
        format.js { render :action => 'update' }
      end
    end
  end

  def delete_card_setting
    @setting = LibraryCardSetting.find(params[:id])
    @course = Course.find(@setting.course_id)
    @setting.delete
    @card_setting = LibraryCardSetting.find_all_by_course_id(@course.id)
    respond_to do |format|
      format.js { render :action => 'destroy' }
    end
  end

  def movement_log
    @sort_order = params[:sort_order]
    order = params[:sort_order]
    @error=false
    if params[:book_log].nil?
      if @sort_order.nil?
        conditions = ["book_movements.issue_date= ? ",Date.today]
        order = 'due_date ASC'
      else
        conditions = ["book_movements.issue_date= ? ",Date.today]
        order = @sort_order
      end
    else
      unless params[:book_log][:start_date].to_date > params[:book_log][:end_date].to_date
        if @sort_order.nil?
          if params[:book_log][:type]=="Due date"
            conditions = ["book_movements.due_date BETWEEN ? and ? ",params[:book_log][:start_date].to_date,params[:book_log][:end_date].to_date]
            order = 'due_date ASC'
          else
            conditions = ["book_movements.issue_date BETWEEN ? and ? ",params[:book_log][:start_date].to_date,params[:book_log][:end_date].to_date]
            order = 'due_date ASC'
          end
        else
          if params[:book_log][:type]=="Due date"
            conditions = ["book_movements.due_date BETWEEN ? and ? ",params[:book_log][:start_date].to_date,params[:book_log][:end_date].to_date]
            order = @sort_order
          else
            conditions= ["book_movements.issue_date BETWEEN ? and ? ",params[:book_log][:start_date].to_date,params[:book_log][:end_date].to_date]
            order = @sort_order
          end
        end
        @log = BookMovement.paginate(:select=>"students.id as student_id,students.admission_no,archived_students.id as archived_student_id,batches.name as batch_name,
                                                  employees.employee_number ,employees.id as employee_id, employee_departments.name as employee_department_name,
                                                  book_movements.*,courses.code as course_code,
                                                  users.first_name,users.last_name,users.student,users.employee,users.is_deleted,users.username,
                                                  books.status as book_status,books.book_number,books.title",
          :joins=>"INNER JOIN `users` ON `users`.id = `book_movements`.user_id
                                                INNER JOIN `books` ON `books`.id = `book_movements`.book_id
                                                LEFT OUTER JOIN `students` ON `users`.id = `students`.user_id
                                                LEFT OUTER JOIN `archived_students` ON `users`.id = `archived_students`.user_id
                                                LEFT OUTER JOIN `employees` ON `users`.id = `employees`.user_id
                                                LEFT OUTER JOIN `batches` ON `batches`.id = `students`.batch_id
                                                LEFT OUTER JOIN `courses` ON `courses`.id = `batches`.course_id
                                                LEFT OUTER JOIN `employee_departments` ON `employee_departments`.id = `employees`.employee_department_id",
                                                
          :conditions=> conditions,
          :page=>params[:page],
          :per_page=>20,
          :order=>order)
      else
        @error = true
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html 'error-div', :text => ''
        page.replace_html 'error-div', :partial => 'error' if @error
        page.replace_html "information", :partial => "movement_log_details" unless @error
      end
    end
  end

  def movement_log_csv 
    parameters={:sort_order => params[:sort_order],:book_log => params[:book_log],:book_log_type => params[:book_log][:type],:book_log_start_date => params[:book_log][:start_date],:book_log_end_date => params[:book_log][:end_date]}
    csv_export('book_movement', 'movement_log', parameters)  
  end

  def book_statistics
    if params[:type] == 'title'
      @books = Book.find_all_by_title(params[:name])
    else

      @books = Book.find_all_by_author(params[:name])
    end
  end

  def book_reservation
    @book_reservation_time_out = Configuration.find_by_config_key('BookReservationTimeOut')
    if request.post?
    end
  end
  def show_date_filter
    month_date
    @target_action=params[:target_action]
    if request.xhr?
      render(:update) do|page|
        page.replace_html "date_filter", :partial=>"filter_dates"
      end
    end
  end

  def library_report
    if validate_date
      
      filter_by_account, account_id = account_filter 

      joins = "INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
                LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
      filter_conditions = "(fa.id IS NULL OR fa.is_deleted = false) "
      if filter_by_account
        filter_conditions += "AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
      else
        filter_values = []
      end
      
      @target_action = 'library_report'
      
      library_id = FinanceTransactionCategory.find_by_name('Library').id
      @grand_total = FinanceTransaction.all(:select => "amount",
        :joins => "LEFT OUTER JOIN students st on st.id = finance_transactions.payee_id 
                        LEFT OUTER JOIN archived_students ast on ast.former_id = finance_transactions.payee_id
                        #{joins}",
        :conditions => ["(transaction_date BETWEEN ? AND ?) AND
                                 finance_transactions.category_id = ? AND #{filter_conditions}",
          @start_date, @end_date, library_id] + filter_values).map {|x| x.amount.to_f }.sum
      
      @total_students = FinanceTransaction.count(
        :joins => "LEFT OUTER JOIN students st on st.id = finance_transactions.payee_id 
                        LEFT OUTER JOIN archived_students ast on ast.former_id = finance_transactions.payee_id 
                                 INNER JOIN batches on batches.id = ast.batch_id or batches.id = st.batch_id 
                                 INNER JOIN courses on courses.id = batches.course_id #{joins}",
        #        :group => "st.id,ast.former_id",
        :conditions => ["finance_transactions.category_id = ? AND 
                                 (transaction_date BETWEEN ? AND ?) AND #{filter_conditions}", library_id, @start_date,
          @end_date] + filter_values,
        :select => "DISTINCT IFNULL(st.admission_no, ast.admission_no)")
      
      @students = FinanceTransaction.paginate(:per_page => 10, :page => params[:page], :total_entries => @total_students,
        :joins => "LEFT OUTER JOIN students st on st.id = finance_transactions.payee_id 
                        LEFT OUTER JOIN archived_students ast on ast.former_id = finance_transactions.payee_id 
                                 INNER JOIN batches on batches.id = ast.batch_id or batches.id = st.batch_id 
                                 INNER JOIN courses on courses.id = batches.course_id #{joins}",
        :group => "st.id,ast.former_id",
        :conditions => ["finance_transactions.category_id = ? AND 
                                 (transaction_date BETWEEN ? AND ?) AND #{filter_conditions}", library_id, @start_date,
          @end_date] + filter_values,
        :select => "IFNULL(st.admission_no, ast.admission_no) AS admission_no, 
                          IFNULL(st.id, ast.former_id) AS student_id, 
                          IF(st.id IS NOT NULL, 'Student', 'ArchivedStudent') AS student_type,
                          IFNULL(st.batch_id, ast.batch_id) AS batch_id, 
                          SUM(finance_transactions.amount) AS amount, 
                          IFNULL(CONCAT(st.first_name, ' ', st.last_name),
                          CONCAT(ast.first_name, ' ', ast.last_name)) AS name, 
                          CONCAT(batches.name, '-', courses.code) AS batch_name")
     
      if request.xhr?
        render(:update) do|page|
          page.replace_html "fee_report_div", :partial=>"library_report"
        end
      end
    else
      render_date_error_partial
    end
  end

  def library_report_csv
    if date_format_check
      
      filter_by_account, account_id = account_filter

      joins = "INNER JOIN finance_transaction_receipt_records ftrr
                       ON ftrr.finance_transaction_id = finance_transactions.id
                LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
      filter_conditions = "(fa.id IS NULL OR fa.is_deleted = false) "

      if filter_by_account
        filter_conditions += "AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
        # joins = "INNER JOIN finance_transaction_receipt_records ON finance_transaction_receipt_records.finance_transaction_id = finance_transactions.id"
      else
        filter_values = []
      end
      
      library_id = FinanceTransactionCategory.find_by_name('Library').id
      students = FinanceTransaction.all(:group => "st.id,ast.former_id",
        :joins => "LEFT OUTER JOIN students st on st.id=finance_transactions.payee_id 
                        LEFT OUTER JOIN archived_students ast on ast.former_id=finance_transactions.payee_id 
                                 INNER JOIN batches on batches.id=ast.batch_id or batches.id=st.batch_id 
                                 INNER JOIN courses on courses.id=batches.course_id #{joins}",
        :conditions => ["finance_transactions.category_id = ? AND 
                                 (transaction_date BETWEEN ? AND ?) AND #{filter_conditions}", library_id, @start_date,
          @end_date] + filter_values,
        :select => "IFNULL(st.admission_no, ast.admission_no) AS admission_no, 
                          IFNULL(st.id, ast.former_id) AS student_id, 
                          IF(st.id IS NOT NULL, 'Student', 'ArchivedStudent') AS student_type,
                          IFNULL(st.batch_id, ast.batch_id) AS batch_id, 
                          SUM(finance_transactions.amount) AS amount, 
                          IFNULL(CONCAT(st.first_name, ' ', st.last_name),
                          CONCAT(ast.first_name, ' ', ast.last_name)) AS name, 
                          CONCAT(batches.name, '-', courses.code) AS batch_name")
      #        :select=>"ifnull(st.admission_no,ast.admission_no) as admission_no,ifnull(st.id,ast.former_id) as student_id,if(st.id is not null,'Student','ArchivedStudent') as student_type,ifnull(st.batch_id,ast.batch_id) as batch_id,sum(finance_transactions.amount) as amount,ifnull(concat(st.first_name,' ',st.last_name) ,concat(ast.first_name,' ',ast.last_name)) as name,concat(batches.name,'-',courses.code) as batch_name")
      csv_string = FasterCSV.generate do |csv|
        csv << [t('library_transaction_report')]
        csv << [t('start_date'),format_date(@start_date)]
        csv << [t('end_date'),format_date(@end_date)]
        csv << [t('fee_account_text'), "#{@account_name}"] if @accounts_enabled
        csv << ""
        csv << [t('name'),t('admission_no'),t('batch'),t('amount')]
        total = 0
        students.each do |s|
          unless s.amount == 0
            row = []
            row << s.name
            row << s.admission_no
            row << s.batch_name
            row << precision_label(s.amount)
            total += s.amount.to_f
            csv << row
          end
        end
        csv << ""
        csv << [t('net_income'),"","",precision_label(total)]
      end
      filename = "#{t('library_transaction_report')}-#{format_date(@start_date)}-#{format_date(@end_date)}.csv"
      send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
    end
  end


  def batch_library_report
    if validate_date
      
      filter_by_account, account_id = account_filter

      joins = "INNER JOIN finance_transaction_receipt_records ftrr
                       ON ftrr.finance_transaction_id = finance_transactions.id
                LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
      filter_conditions = "(fa.id IS NULL OR fa.is_deleted = false) "

      if filter_by_account
        filter_conditions += "AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
      else
        filter_values = []
      end
      
      @target_action = "batch_library_report"
      student = Student.find_by_id(params[:id])
      @student_name = student.present? ? student.full_name: t('unknown')
      library_id = FinanceTransactionCategory.find_by_name('Library').id
      @grand_total = FinanceTransaction.all(:select => "amount", :joins => joins,
        :conditions => ["category_id = ? AND payee_id = ? AND 
                                 (transaction_date BETWEEN ? AND ?) AND #{filter_conditions}",
          library_id, params[:id], @start_date, @end_date ] + filter_values ).map {|x| x.amount.to_f }.sum
      
      @transactions = FinanceTransaction.paginate(:include => :transaction_receipt, :per_page=>10,
        :page => params[:page], :joins => joins, 
        :conditions => ["payee_id = ? AND category_id = ? AND
                                 (transaction_date BETWEEN ? AND ?) AND #{filter_conditions}",
          params[:id], library_id, @start_date, @end_date ] + filter_values)
      
      if request.xhr?
        render(:update) do|page|
          page.replace_html "fee_report_div", :partial=>"batch_library_report"
        end
      end
    else
      render_date_error_partial
    end
  end

  def batch_library_report_csv
    if date_format_check
      
      filter_by_account, account_id = account_filter

      joins = "INNER JOIN finance_transaction_receipt_records ftrr
                       ON ftrr.finance_transaction_id = finance_transactions.id
                LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
      filter_conditions = "(fa.id IS NULL OR fa.is_deleted = false) "

      if filter_by_account
        filter_conditions += "AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
      else
        filter_values = []
      end
      
      library_id = FinanceTransactionCategory.find_by_name('Library').id
      transactions = FinanceTransaction.all(:include => :transaction_receipt, :joins => joins,
        :conditions => ["payee_id = ? AND category_id = ? AND (transaction_date BETWEEN ? AND ?) AND
                                 #{filter_conditions}", params[:id], library_id, @start_date, @end_date ] + filter_values)
      
      csv_string = FasterCSV.generate do |csv|
        csv << [t('library_transaction_report')]
        csv << [t('start_date'), format_date(@start_date)]
        csv << [t('end_date'), format_date(@end_date)]
        csv << [t('fee_account_text'), "#{@account_name}"] if @accounts_enabled
        csv << ""
        csv << [t('student_name'), "#{transactions.first.student_payee.full_name} (#{transactions.first.student_payee.admission_no})"]
        csv << [t('course'), transactions.first.student_payee.batch.course.course_name]
        csv << [t('batch'),transactions.first.student_payee.batch.name]
        csv << ""
        csv << [t('receipt_no'), t('date_text'), t('amount')]
        csv << []
        total = 0
        transactions.each do |s|
          unless s.amount == 0
            row = []
            row << s.receipt_number
            row << format_date(s.created_at, :format => :short_date)
            row << precision_label(s.amount)
            total += s.amount.to_f
            csv << row
          end
        end
        csv << ""
        csv << [t('net_income'),"",precision_label(total)]
      end
      filename = "#{t('library_transaction_report')}-#{format_date(@start_date)}-#{format_date(@end_date)}.csv"
      send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
    end
  end

  def student_library_details
    @current_user = current_user
    @available_modules = Configuration.available_modules
    @student = Student.find(params[:id])
    @reserved = @student.book_reservations
    @borrowed = @student.book_movements.find(:all, :conditions=>["status !='Returned'"])
  end

  def employee_library_details
    @current_user = current_user
    @available_modules = Configuration.available_modules
    @employee = Employee.find(params[:id])
    @reserved = @employee.book_reservations
    @borrowed = @employee.book_movements.find(:all, :conditions=>["status !='Returned'"])
    @new_reminder_count = Reminder.find_all_by_recipient(@current_user.id, :conditions=>"is_read = false")
  end
  
  private
  def csv_export(model, method, parameters)
    csv_report=AdditionalReportCsv.find_by_model_name_and_method_name(model, method)
    if csv_report.nil?
      csv_report=AdditionalReportCsv.new(:model_name => model, :method_name => method, :parameters => parameters, :status => true)
      if csv_report.save
        Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id),{:queue => "additional_reports"})
      end
    else
      unless csv_report.status
        if csv_report.update_attributes(:parameters => parameters, :csv_report => nil, :status => true)
          Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id),{:queue => "additional_reports"})
        end
      end 
    end
    flash[:notice]="#{t('csv_report_is_in_queue')}"
    redirect_to :controller=> :reports, :action => :csv_reports, :model => model, :method => method
  end
end
