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
class BooksController < ApplicationController
  before_filter :login_required
  before_filter :check_book_status, :only =>[ :edit , :update ]

  filter_access_to :all
  include FeeReceiptMod
  include ReceiptPrinterHelper
  helper_method(:get_stylesheet_for_current_receipt_template,:get_stylesheet_for_receipt_template,:get_current_receipt_partial,:get_partial_for_current_receipt_template,:receipt_path,:get_receipt_partial,:precision_label_with_currency,
    :has_fine?,:has_discount?,:has_tax?,:has_previously_paid_fees?,:has_roll_number?,:particular_has_discount,:particular_has_previous_payments,
    :current_receipt_template_preview_url,:reference_no_label,:clean_output,:has_due?,:has_due_date?,:has_particulars?)
  def index    
    @books = Book.all(:order => "soundex(book_number),length(book_number),book_number ASC").paginate(:page => params[:page],:include=>:tags)
    @count = @books.total_entries
  end
  
#  def manage_books_csv_export
#    if params[:sort].present?
#      sort = params[:sort][:on]
#      books = Book.search(:status_like=>"#{sort}").all(:joins=>[""],:order => "soundex(book_number),length(book_number),book_number ASC",:include=>:tags)
#    else
#      books = Book.all(:order => "soundex(book_number),length(book_number),book_number ASC",:include=>:tags)
#    end
#    csv_string = Book.get_manage_book_csv_data(books)
#    filename = "BooksExport#{params[:sort][:on]}#{Time.now.to_date.to_s}.csv"
#    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
#  end
  
  def manage_books_csv_export    
    parameters={:books => params[:books],:sort_on => params[:sort][:on],:index=> params[:index]}
    csv_export('book', 'manage_books', parameters)
  end

  def new
    @tagg = []
    @book_number =Book.find(:first,:order=>"LENGTH(REPLACE(book_number, ' ', '')) DESC, book_number DESC").book_number.next if Book.count >= 1
    unless params[:author].nil?
      @book_title = params[:title]
      @author = params[:author]
      @detail = Book.find_by_author_and_title(@author, @book_title)
      @tagg = @detail.tag_list
    else
      @book_title = ''
      @author = ''
    end
    @book = Book.new
    @tags = Tag.find(:all)
  end

  def list_barcode_field
    p params[:create_type]
    if params[:create_type]=="barcode"
      render :update do |page|
        page.replace_html 'barcode_field' , :partial=>'list_barcode_field'
        page.replace_html 'count_area', ''
      end
    else
      render :update do |page|
        page.replace_html 'barcode_field' , ''
        page.replace_html 'count_area', :partial=>'list_count_field'
      end
    end
  end

  def create
    @tagg = []
    @book = Book.find(:last)
    @book_number = @book.book_number.next unless @book.nil?
    @book_number = params[:book][:book_number] unless params[:book][:book_number].nil?
    unless params[:author].nil?
      @book_title = params[:title]
      @author = params[:author]
      @detail = Book.find_by_author_and_title(@author, @book_title)
      @tagg = @detail.tag_list
    else
      @book_title = ''
      @author = ''
    end
    @book = Book.new
    @tags = Tag.find(:all)
    @book = Book.new(params[:book])
    @created_books = Array.new
    @count = params[:tag][:count].to_i
    @custom_tags = params[:tag][:list]
    tags = @custom_tags.split(',')
    unless params[:tag][:count] == ""
      saved = 0
      temp_book_number = params[:book][:book_number]
      tags << params[:book][:tag_list]
      Book.transaction do
        @count.times do |c|
          book_number = temp_book_number
          if @book = Book.create(:title=> params[:book][:title], :author=> params[:book][:author], :tag_list =>tags, :book_number =>book_number, :status=>'Available',:barcode=>params[:book][:barcode],:book_add_type=>params[:book][:book_add_type])
            unless @book.id.nil?
              saved += 1
              Book.update(@book.id, :tag_list => tags)
              temp_book_number = temp_book_number.next
              @created_books = @created_books.push @book.id
            else
              raise ActiveRecord::Rollback, "already taken"
            end
          end
        end
      end
      if  saved == @count
        flash[:notice]="#{t('flash1')}"
        redirect_to additional_data_books_path(:id => @created_books)
      else
        @book_barcode=params[:book][:barcode]
        @book_add_type=params[:book][:book_add_type]
        render 'new'
      end
    else
      @book.errors.add_to_base("#{t('flash5')}")
      render 'new'
    end
  end

  def edit
    @book = Book.find(params[:id])
    @tags = Tag.find(:all)
  end

  def update
    @book = Book.find(params[:id])
    @tags = Tag.all
    @custom_tags = params[:tag][:list]
    tags = @custom_tags.split(',')
    params[:book][:tag_list]=[] if params[:book][:tag_list].blank?
    params[:book][:tag_list] << tags unless tags.blank?
    if @book.update_attributes(params[:book])
      flash[:notice]="#{t('flash2')}"
      redirect_to edit_additional_data_books_path(:id => @book.id)
    else
      render 'edit'
    end
  end

  def manage_barcode
    if request.post?
      if params[:search][:search_by] == 'tag'
        @books=Book.find_tagged_with(params[:search][:name]) if params[:search][:name].length>=3
      elsif params[:search][:search_by] == 'title'
        @books=Book.find(:all,:conditions=>['books.title LIKE ?',"%#{params[:search][:name]}%"]) if params[:search][:name].length>=3
      elsif params[:search][:search_by] == 'author'
        @books=Book.find(:all,:conditions=>['books.author LIKE ?',"%#{params[:search][:name]}%"]) if params[:search][:name].length>=3
      else
        if params[:search][:name].length>=3
          @books = Book.find(:all,:conditions=>['books.book_number LIKE ?',"%#{params[:search][:name]}%"],:limit=>200)
        else
          @books = Book.find(:all,:conditions=>['books.book_number LIKE ?',"#{params[:search][:name]}"])
        end
      end
      render :update do |page|
        page.replace_html 'book-list', :partial => 'barcode_manage'
      end
    end
  end

  def update_barcode
    @book_errors = []
    @book_current_value= []
    params[:book].each_pair do|k,val|
      @books_to_update=Book.find(k)
      unless @books_to_update.barcode==val["barcode"]
        unless @books_to_update.update_attributes(val)
          @book_errors.push(k)
          @book_current_value[k.to_i]=val["barcode"]
        end
      end
    end
    if @book_errors.empty?
      render :update do |page|
        page.replace_html 'book-list', :text=>"<p class='flash-msg'>#{t('books.books_updated')}<p>"
      end
    else
      @books = Book.find_all_by_id(params[:book_ids].split(","))
      render :update do |page|
        page.replace_html 'book-list', :partial=>"barcode_manage"
      end
    end
  end

  def additional_data
    @book = Book.new
    @books = Book.find_all_by_id(params[:id])
    @additional_fields = BookAdditionalField.find(:all, :conditions=> "is_active = true", :order=>"priority ASC")
    if @additional_fields.empty?
      flash[:notice] = "Books created successfully."
      redirect_to books_path and return
    end
    if request.post?
      @books.each do |book|
        @error=false
        @book_additional_details = BookAdditionalDetail.find_all_by_book_id(book.id)
        mandatory_fields = BookAdditionalField.find(:all, :conditions=>{:is_mandatory=>true, :is_active=>true})
        mandatory_fields.each do|m|
          unless params[:book_additional_details][m.id.to_s.to_sym].present?
            @book.errors.add_to_base("#{m.name} must contain atleast one selected option.")
            @error=true
          else
            if params[:book_additional_details][m.id.to_s.to_sym][:additional_info]==""
              @book.errors.add_to_base("#{m.name} cannot be blank.")
              @error=true
            end
          end
        end
        unless @error==true
          params[:book_additional_details].each_pair do |k, v|
            addl_info = v['additional_info']
            addl_field = BookAdditionalField.find_by_id(k)
            if addl_field.input_type == "has_many"
              addl_info = addl_info.join(", ")
            end
            prev_record = BookAdditionalDetail.find_by_book_id_and_book_additional_field_id(book.id, k)
            unless prev_record.nil?
              unless addl_info.present?
                prev_record.destroy
              else
                prev_record.update_attributes(:additional_info => addl_info)
              end
            else
              addl_detail = BookAdditionalDetail.new(:book_id => book.id,
                :book_additional_field_id => k,:additional_info => addl_info)
              addl_detail.save if addl_detail.valid?
            end
          end
        else
          render :additional_data and return
        end
      end
      flash[:notice] = "Book saved with additional data successfully"
      redirect_to books_path
    end
  end

  def edit_additional_data
    @book = Book.find(params[:id])
    @additional_fields = BookAdditionalField.find(:all, :conditions=> "is_active = true", :order=>"priority ASC")
    @book_additional_details = BookAdditionalDetail.find_all_by_book_id(@book.id)
    if @additional_fields.blank?
      flash[:notice] = t('book_updated')
      redirect_to @book
    end
    if request.post?
      @error=false
      mandatory_fields = BookAdditionalField.find(:all, :conditions=>{:is_mandatory=>true, :is_active=>true})
      mandatory_fields.each do|m|
        flag = nil
        unless params[:book_additional_details][m.id.to_s.to_sym].present?
          @book.errors.add_to_base("#{m.name} must contain atleast one selected option.")
          @error=true
        else
          if params[:book_additional_details][m.id.to_s.to_sym][:additional_info]==""
            @book.errors.add_to_base("#{m.name} cannot be blank.")
            @error=true
          else
            params[:book_additional_details][m.id.to_s.to_sym][:additional_info].each do |add_info|
              if add_info.present?
                flag = 1
                break
              end
            end
            @book.errors.add_to_base("#{m.name} must contain atleast one selected option.") if flag != 1
            @error=true if flag != 1
          end
        end
      end
      unless @error==true
        params[:book_additional_details].each_pair do |k, v|
          addl_info = v['additional_info']
          addl_field = BookAdditionalField.find_by_id(k)
          if addl_field.input_type == "has_many"
            if addl_info.reject(&:empty?).empty?
              addl_info=nil
            else
              addl_info = addl_info.reject(&:empty?).join(", ")
            end
          end
          prev_record = BookAdditionalDetail.find_by_book_id_and_book_additional_field_id(@book.id, k)
          unless prev_record.nil?
            unless addl_info.present?
              prev_record.destroy
            else
              prev_record.update_attributes(:additional_info => addl_info)
            end
          else
            addl_detail = BookAdditionalDetail.new(:book_id => @book.id,
              :book_additional_field_id => k,:additional_info => addl_info)
            addl_detail.save if addl_detail.valid?
          end
        end
      else
        render :edit_additional_data and return
      end

      flash[:notice] = "Book saved with additional data successfully"
      redirect_to books_path
    end
  end

  def show    
    
    @book = Book.find(params[:id])
    @lender = Student.first(:conditions => ["admission_no LIKE BINARY(?)",@book.book_movement.user.username]) unless @book.book_movement_id.nil?
    @lender ||= ArchivedStudent.first(:conditions => ["admission_no LIKE BINARY(?)",@book.book_movement.user.username]) unless @book.book_movement_id.nil?
    @lender ||= Employee.first(:conditions => ["employee_number LIKE BINARY(?)",@book.book_movement.user.username]) unless @book.book_movement_id.nil?
    @lender ||= ArchivedEmployee.first(:conditions => ["employee_number LIKE BINARY(?)",@book.book_movement.user.username]) unless @book.book_movement_id.nil?
    @reservations = BookReservation.find_all_by_book_id(@book.id)
    @book_reserved = BookReservation.find_by_book_id(@book.id)      
    @book_movement=@book.book_movement
    @additional_details = BookAdditionalDetail.find_all_by_book_id(@book.id)
  end

  def destroy
    @book = Book.find(params[:id])
    if @book.book_movement_id.nil? #or @book.status=='Lost'
      @book.destroy
      flash[:notice] ="#{t('flash3')}"
    else
      flash[:warn_notice] ="#{t('flash4')}"
    end
    redirect_to books_path
  end

  def sort_by
    @sort = params[:sort][:on]
    @books = Book.search(:status_like=>"#{@sort}").all(:order => "soundex(book_number),length(book_number),book_number ASC").paginate(:page=>params[:page],:include=>:tags)
    @count = @books.total_entries
    render(:update) do |page|
      page.replace_html 'books', :partial=>'books'
    end
  end

  def add_additional_details
    @all_details = BookAdditionalField.find(:all,:order=>"priority ASC")
    @additional_details = BookAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
    @inactive_additional_details = BookAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
    @additional_field = BookAdditionalField.new
    @book_additional_field_option = @additional_field.book_additional_field_options.build
    if request.post?
      priority = 1
      unless @all_details.empty?
        last_priority = @all_details.map{|r| r.priority}.compact.sort.last
        priority = last_priority + 1
      end
      @additional_field = BookAdditionalField.new(params[:book_additional_field])
      @additional_field.priority = priority
      if @additional_field.save
        flash[:notice] = "Additional field added successfully"
        redirect_to :controller => "books", :action => "add_additional_details"
      end
    end
  end

  def change_field_priority
    @additional_field = BookAdditionalField.find(params[:id])
    priority = @additional_field.priority
    @additional_fields = BookAdditionalField.find(:all, :conditions=>{:is_active=>true}, :order=> "priority ASC").map{|b| b.priority.to_i}
    position = @additional_fields.index(priority)
    if params[:order]=="up"
      prev_field = BookAdditionalField.find_by_priority(@additional_fields[position - 1])
    else
      prev_field = BookAdditionalField.find_by_priority(@additional_fields[position + 1])
    end
    @additional_field.update_attributes(:priority=>prev_field.priority)
    prev_field.update_attributes(:priority=>priority.to_i)
    @additional_field = BookAdditionalField.new
    @additional_details = BookAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
    @inactive_additional_details = BookAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
    render(:update) do|page|
      page.replace_html "category-list", :partial=>"additional_fields"
    end
  end

  def edit_additional_details
    @additional_details = BookAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
    @inactive_additional_details = BookAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
    @additional_field = BookAdditionalField.find(params[:id])
    @book_additional_field_option = @additional_field.book_additional_field_options
    if request.get?
      render :action=>'add_additional_details'
    else
      if @additional_field.update_attributes(params[:book_additional_field])
        flash[:notice] = "Additional field updated successfully"
        redirect_to :action => "add_additional_details"
      else
        render :action=>"add_additional_details"
      end
    end
  end

  def delete_additional_details
    books = BookAdditionalDetail.find(:all ,:conditions=>"book_additional_field_id = #{params[:id]}")
    if books.blank?
      BookAdditionalField.find(params[:id]).destroy
      @additional_details = BookAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
      @inactive_additional_details = BookAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
      flash[:notice]="Additional field deleted successfully"
      redirect_to :action => "add_additional_details"
    else
      flash[:notice]="Additional field is in use and cannot be deleted"
      redirect_to :action => "add_additional_details"
    end
  end

  def library_transactions
    @transactions=FinanceTransaction.paginate(:per_page=>20,:page=>params[:page],
      :joins => "INNER JOIN finance_transaction_receipt_records ftrr
                         ON ftrr.finance_transaction_id = finance_transactions.id
                  LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
      :conditions => ["finance_transactions.created_at >='#{Date.today - Date.today.day+1}' AND
                       finance_transactions.created_at <'#{Date.today+1}' AND
                       finance_type='BookMovement' AND #{active_account_conditions(true, 'ftrr')}"],
      :order => 'created_at desc')
  end

  def search_library_transactions
    @transactions=FinanceTransaction.paginate(:per_page=>20,:page=>params[:page],
      :joins => "LEFT OUTER JOIN students ON students.id = payee_id
                 LEFT OUTER JOIN archived_students on former_id = payee_id
                      INNER JOIN finance_transaction_receipt_records ftrr
                              ON ftrr.finance_transaction_id = finance_transactions.id
                       LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
      :conditions => ["(students.admission_no LIKE ? OR students.first_name LIKE ? OR
                        archived_students.admission_no LIKE ? OR archived_students.first_name LIKE ?) and
                       finance_type = ? AND #{active_account_conditions(true, 'ftrr')}","#{params[:query]}%",
                      "#{params[:query]}%","#{params[:query]}%", "#{params[:query]}%",'BookMovement'],
      :order => "finance_transactions.created_at desc")  unless params[:query] == ''
    render :update do |page|
      page.replace_html 'deleted_transactions', :partial => "books/search_library_transactions"
    end
    #render :partial => "books/search_library_transactions"
  end

  def library_transaction_filter_by_date
    @start_date = params[:s_date]
    @end_date = params[:e_date]
    @transactions = FinanceTransaction.paginate(:per_page=>20,:page=>params[:page],
      :joins => "LEFT OUTER JOIN students ON students.id = payee_id
                 LEFT OUTER JOIN archived_students on former_id = payee_id
                      INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
                       LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
      :conditions => ["(fa.id IS NULL OR fa.is_deleted = false) AND (finance_transactions.created_at >='#{@start_date}' and
                        finance_transactions.created_at <'#{@end_date.to_date+1.day}') and
                       finance_type='BookMovement' and (payee_id=students.id or payee_id=former_id)"],
      :order=>'created_at desc')
    render :update do |page|
      page.replace_html 'deleted_transactions', :partial => "books/library_transactions_date_filter"
    end
  end
  #render :partial => "books/library_transactions"
  def delete_library_transaction
    @financetransaction=FinanceTransaction.find(params[:id])
    if @financetransaction
      @financetransaction.cancel_reason = params[:reason]
      @financetransaction.destroy
    end
    if params[:s_date].present?
      @start_date=params[:s_date]
      @end_date=params[:e_date]
      @transactions=FinanceTransaction.paginate(:per_page=>20,:page=>params[:page],:joins=>'LEFT OUTER JOIN students ON students.id = payee_id',:conditions=>["(finance_transactions.created_at >='#{@start_date}' and finance_transactions.created_at <='#{@end_date}') and (finance_type='BookMovement' and payee_id=students.id)"],:order=>'created_at desc')
      render :update do |page|
        page.replace_html 'deleted_transactions', :partial => "books/library_transactions_date_filter"
      end
    elsif params[:query].present?
      @transactions=FinanceTransaction.paginate(:per_page=>20,:page=>params[:page],:joins=>'LEFT OUTER JOIN students ON students.id = payee_id',:conditions => ["(students.admission_no LIKE ? OR students.first_name LIKE ?) and finance_type=?",
          "#{params[:query]}%","#{params[:query]}%",'BookMovement'],:order=>'created_at desc')  unless params[:query] == ''
      render :update do |page|
        page.replace_html 'deleted_transactions', :partial => "books/search_library_transactions"
      end
    else
      @transactions=FinanceTransaction.paginate(:per_page=>20,:page=>params[:page],:conditions=>["created_at >='#{Date.today}' and created_at <'#{Date.today+1.day}' and finance_type='BookMovement'"],:order=>'created_at desc')
      render :update do |page|
        page.replace_html 'deleted_transactions', :partial => "books/library_transactions"
      end
    end
  end
 
  def generate_library_fine_receipt_pdf
    finance_transactions = FinanceTransaction.find(params[:transaction_id]).to_a
#    finance_transactions = FinanceTransaction.find_all_by_id(params[:transaction_id], 
#      :include => :finance_transaction_receipt_record)
    template_ids = []
    @transactions = finance_transactions.map do |ft| 
      receipt_data = ft.receipt_data
      template_ids << receipt_data.template_id = ft.fetch_template_id
      receipt_data
    end
    template_ids = template_ids.compact.uniq
#    configs = ['PdfReceiptSignature', 'PdfReceiptSignatureName', 
#      'PdfReceiptCustomFooter','PdfReceiptAtow','PdfReceiptNsystem', 'PdfReceiptHalignment']
#    fetch_config_hash configs
#    @config = Configuration.get_multiple_configs_as_hash configs
    
#    @default_currency = Configuration.default_currency
    #    template_ids = finance_transactions.map {|x| x.fetch_template_id }.uniq.compact
    @data = {:templates => template_ids.present? ? FeeReceiptTemplate.find(template_ids).group_by(&:id) : {} }
    render :pdf => 'generate_fee_receipt_pdf',
    :template => "finance_extensions/receipts/generate_fee_receipt_pdf.erb",
      :margin =>{:top => 2, :bottom => 20, :left => 5, :right => 5},
      :header => {:html => { :content=> ''}},  :footer => {:html => {:content => ''}}, 
      :show_as_html => params.key?(:debug)
#    @ft = FinanceTransaction.find(params[:transaction_id])
#    @config = Configuration.get_multiple_configs_as_hash ['PdfReceiptSignature', 'PdfReceiptSignatureName', 'PdfReceiptCustomFooter','PdfReceiptAtow','PdfReceiptNsystem', 'PdfReceiptHalignment']
#    @default_currency = Configuration.default_currency
#    @currency = currency
#    @book_name_and_no = (@ft.finance.book.book_number)+" : "+(@ft.finance.book.title)
#    @library_fine_amount = @ft.amount.to_f
#    @online_transaction_id = nil
#    @full_course_name = @ft.batch.full_name
#    @roll_number = @ft.fetch_payee.roll_number
#    @f_payee = @ft.fetch_payee.immediate_contact_id
#    if @f_payee.present?
#      @guardian = Guardian.find_by_id(@f_payee)
#      if @guardian.present?
#        @parent = @ft.fetch_payee.try(:immediate_contact).try(:full_name) 
#      else
#        @parent = ArchivedGuardian.find_by_former_id(@f_payee).try(:full_name)
#      end
#    end
#    
#    
##    get_library_fine_details(@ft)
#    render :pdf => 'generate_library_fine_receipt_pdf',
#      :template=>'books/generate_library_fine_receipt_pdf.erb',
#      :margin =>{:top=>2,:bottom=>20,:left=>5,:right=>5},
#      :header => {:html => { :content=> ''}}, 
#      :footer => {:html => {:content => ''}}, 
#      :show_as_html => params.key?(:debug)
  end
  
  def generate_library_fine_receipt
#    @config = Configuration.get_multiple_configs_as_hash ['PdfReceiptSignature', 'PdfReceiptSignatureName', 
#      'PdfReceiptCustomFooter','PdfReceiptAtow','PdfReceiptNsystem', 'PdfReceiptHalignment']
#    @default_currency = Configuration.default_currency
#      get_library_fine_details(params[:transaction_id])
      
    finance_transactions = FinanceTransaction.find_all_by_id(params[:transaction_id], 
      :include => :finance_transaction_receipt_record)
    
    template_ids = []
    
    @transactions = finance_transactions.map do |ft| 
      receipt_data = ft.receipt_data
      template_ids << receipt_data.template_id = ft.fetch_template_id
      receipt_data
    end
    template_ids = template_ids.uniq.compact
    @data = {:templates => template_ids.present? ? FeeReceiptTemplate.find(template_ids).group_by(&:id) : {} }
    
    render :layout => "print"
   
  end
  
  def search_books
    search_by = params[:search][:search_by]
    @sort = params[:search][:on]
    if search_by == ""
      @books_csv = Book.search(:status_like=>"#{@sort}").all(:order => "soundex(book_number),length(book_number),book_number ASC")
      @books = @books_csv.paginate(:page=>params[:page],:include=>:tags)
      @count = @books.total_entries
    else
      if !params[:search][:name].empty?
        @search_result = Book.search_book(search_by,params[:search][:name])        
          if search_by == "tag"   
            if @sort != ""
             @books_csv = @search_result.find_all_by_status("#{@sort}",:order=>"soundex(book_number),length(book_number),book_number ASC")
             @books = @books_csv.paginate(:page=>params[:page],:include=>:tags) 
            else
             @books_csv = @search_result
             @books = @search_result.paginate(:page=>params[:page],:include=>:tags) 
            end
          else
           @books_csv = @search_result.search(:status_like=>"#{@sort}").all(:order => "soundex(book_number),length(book_number),book_number ASC")
           @books = @books_csv.paginate(:page=>params[:page],:include=>:tags)
          end 
          @count = @books.total_entries
      else
        @books_csv= []
        @books= []
      end  
    end           
    render(:update) do |page|
      page.replace_html 'books', :partial=>'books2'
    end
  end
  
  private

  def check_book_status
    @book = Book.find(params[:id])
    redirect_to :action => :show , :id => @book.id  if @book.status == 'Borrowed'
  end
  
  def get_library_fine_details(transaction_record)
    
    @fts_hash=ActiveSupport::OrderedHash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    fts = FinanceTransaction.find_all_by_id(transaction_record)
    fts.each do |ft|
      @fts_hash[ft.id]["finance_type"]=ft.finance_type
      @fts_hash[ft.id]["book_name_and_number"]=((ft.finance.book.book_number)+" : "+(ft.finance.book.title))
      @fts_hash[ft.id]["receipt_no"]=ft.receipt_number
      @fts_hash[ft.id]["amount"]=ft.amount
      @fts_hash[ft.id]["transaction_date"]=ft.transaction_date
      @online_transaction_id = nil
      @fts_hash[ft.id]["payment_mode"]=ft.payment_mode
      @fts_hash[ft.id]["currency"] = Configuration.currency
      @fts_hash[ft.id]["payee"]["type"]=ft.payee_type
      @fts_hash[ft.id]["payee"]["full_name"]=ft.fetch_payee.full_name
      @fts_hash[ft.id]["payee"]["roll_number"]=ft.fetch_payee.roll_number
      @fts_hash[ft.id]["payee"]["full_course_name"]=ft.batch.full_name
      @fts_hash[ft.id]["payee"]["admission_no"]=ft.fetch_payee.admission_no
      @f_payee = ft.fetch_payee.immediate_contact_id
      if @f_payee.present?
        @guardian = Guardian.find_by_id(@f_payee)
        if @guardian.present?
          @parent = ft.fetch_payee.try(:immediate_contact).try(:full_name) 
        else
          @parent = ArchivedGuardian.find_by_former_id(@f_payee).try(:full_name)
        end
      end
      @fts_hash[ft.id]["payee"]["guardian_name"]= @parent
    end
    @online_transaction_id = nil    
  end
  
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
