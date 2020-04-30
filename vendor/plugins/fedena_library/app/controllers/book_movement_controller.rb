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
class BookMovementController < ApplicationController
  lock_with_feature :finance_multi_receipt_data_updation, :only => [:update_return, :update_renewal]
  before_filter :login_required
  filter_access_to :all
  before_filter :set_precision

  def issue_book
    @book = Book.find(params[:id])
    @issued = BookMovement.find_by_book_id(@book.id, :conditions=>"status !='Returned' ")
    @reserved= BookReservation.find_by_book_id(@book.id)
    @event = Event.new
    @user_event = UserEvent.new
    @movement = BookMovement.new(params[:issue])

    unless params[:user_id].nil?
      @user = User.find(params[:user_id])
      if @user.student?
        @student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",@user.username])
        unless @student.present?
          flash[:notice] = "Student left institution."
          redirect_to :controller => "books", :action => "index" and return
        end
        @issueable = LibraryCardSetting.find_by_course_id(@student.batch.course.id, :conditions=>["student_category_id='#{@student.student_category_id}'"  ]) unless @student.student_category_id.nil?
        @issueable ||= LibraryCardSetting.find_by_course_id(@student.batch.course.id, :conditions=>["student_category_id is NULL"  ])
      elsif @user.employee?
        @employee = Employee.first(:conditions => ["employee_number LIKE BINARY(?)",@user.username])
        unless @employee.present?
        flash[:notice] = "Employee left institution"
        redirect_to :controller => "books", :action => "index" and return
        end
      end
      @in_hand_books = BookMovement.find(:all, :conditions=>["user_id = #{@user.id} and status != 'Returned'"])
    end
    @book_reserved = BookReservation.find_by_book_id(@book.id)
    unless @book_reserved.nil?
      flash[:notice]  = "This book is already reserved"
    end



    if request.post?
      unless @book.tags.collect{|t| t.name}.include?("Reference Book")
        if @book.book_movement_id.nil?
          unless @book.status=='Lost' or User.find(params[:issue][:user_id]).is_deleted?
            @user_event= UserEvent.new
            if @movement.save
              @reserved = BookReservation.find_by_book_id(@movement.book_id)
              @reserved.delete unless @reserved.nil?
              BookMovement.update(@movement.id, :status=>'Issued')
              Book.update(@book.id, :book_movement_id=>@movement.id, :status=>'Borrowed')
              @event.title = "#{t('library_book_return')}"
              @event.description = "#{t('book_title')}: #{@book.title} #{t('with_book_number')}: #{@book.book_number}"
              @event.start_date =(params[:issue][:due_date])
              @event.end_date =(params[:issue][:due_date])
              @event.is_due = true
              @event.origin = @movement
              @event.save
              @user_event.user_id = params[:issue][:user_id]
              @user_event.event_id = @event.id
              @user_event.save
              @user = User.find(params[:issue][:user_id])


              flash[:notice] = "#{t('flash1')}"
              redirect_to :controller=>'book_movement' ,:action=>'direct_issue_book'
            end
          else
            flash[:notice] = "#{t('flash2')}"
            redirect_to :controller=>'book_movement' ,:action=>'issue_book', :id=>@book
          end
        else
          flash[:warn_notice] = "#{t('flash3')}"
          redirect_to :controller=>'book_movement' ,:action=>'direct_issue_book'
        end
      else
        flash[:notice] = t('reference_cant_be_issued')
        redirect_to :controller=>'book_movement' ,:action=>'direct_issue_book', :id=>@book
      end

    end
  end



  def user_search
    @nature = params[:user][:nature]
    unless params[:user][:name].nil?
      search_string = params[:user][:name].strip
      if params[:user][:nature] == 'student'
        @student_user = Student.search_by_admission_no_or_name(search_string).all(:include=>{:batch=>:course})
      else
        @employee_user = Employee.search_by_employee_no_or_name(search_string).all(:include=>:employee_department)
      end
    end
    render(:update) do |page|
      page.replace_html 'user_list', :partial=>'user_list'
    end
  end

  def update_user
    render(:update) do |page|
      if params[:id2] == 'student'
        @student = Student.find(params[:id])
        @user =@student.user
        @issueable = LibraryCardSetting.find_by_course_id(@student.batch.course.id, :conditions=>["student_category_id='#{@student.student_category_id}'"  ]) unless @student.student_category_id.nil?
        @issueable ||= LibraryCardSetting.find_by_course_id(@student.batch.course.id, :conditions=>["student_category_id is NULL"  ])
        @in_hand_books = BookMovement.find(:all, :conditions=>["user_id = #{@user.id} and status != 'Returned'"])
        page.replace_html 'user', :partial=>'student_user'
      else
        @employee = Employee.find(params[:id])
        @user = @employee.user
        @in_hand_books = BookMovement.find(:all, :conditions=>["user_id = #{@user.id} and status != 'Returned'"])
        page.replace_html 'user', :partial=>'employee_user'
      end
    end
  end

  def return_book
    flash[:warn_notice]=nil
    if params[:book_id]
      @book = Book.borrowed.find(params[:book_id])
      if @book.present?
        @book_detail = BookMovement.find(@book.book_movement_id) unless @book.book_movement_id.nil?
      end
    end
    if request.post?
      if params[:book][:book_query].present?
        @books = Book.borrowed.find(:all,:conditions=>["barcode=? or book_number=?",params[:book][:book_query],params[:book][:book_query]])
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html 'book-list', :partial => 'book_list'
      end
    end
  end


  def return_book_detail

  end

  def update_return
    @return = BookMovement.find(params[:id])
    unless params[:return].nil?
      @fine = params[:return][:fine]
      if @return.user.student? and (@fine.present? and @fine.to_f != 0.to_f)
        @student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",@return.user.username])
        library_id = FinanceTransactionCategory.find_by_name('Library').id
        transaction=FinanceTransaction.new(:amount=>@fine, :category_id=>library_id, :title=>'Library fine', :finance=>@return, :payee=>@student,:transaction_date=>FedenaTimeSet.current_time_to_local_time(Time.now).to_date,:batch_id=>@student.batch_id)
        #render :text=>c.errors.full_messages and return
        if transaction.save
          error=false
        else
          error=true
        end
      end
    end
    if error.nil? or error==false
      BookMovement.update(@return.id, :status=>'Returned')
      @return.event.destroy
      @book=Book.find(@return.book_id)
      if @book.book_reservations.empty?
        @book.update_attributes(:status=>'Available', :book_movement_id=>'')
      else
        @book.update_attributes(:status=>'Reserved', :book_movement_id=>'')
      end
      flash[:notice] = "#{t('flash6')}"
      redirect_to :action=> "return_book"
    else
      flash[:warn_notice] = "#{t('finance.flash24')}"
      redirect_to :action => 'return_book',:book_id=>@return.book.id
    end
  end

  def reserve_book
    @book = Book.find(params[:id])
    @exist = BookReservation.find_by_user_id_and_book_id(current_user.id, @book.id)
    @reserve = BookReservation.create(:user_id=>current_user.id, :book_id=>@book.id, :reserved_on=>Time.now) if @exist.nil?
    @reservations = BookReservation.find_all_by_book_id(@book.id)
    @book.update_attributes(:status=>'Reserved') unless @book.status == 'Borrowed'
    render(:update) do |page|
      page.replace_html 'reserve_book', :text=>''
      page.replace_html 'book_reserve', :partial=>'book_reserve'

    end
  end

  def direct_issue_book
    flash[:warn_notice]=nil
    if params[:book_id]
      @book = Book.available.find(params[:book_id])
      @book_detail = BookMovement.find(@book.book_movement_id) unless @book.book_movement_id.nil?
    end
    if request.post?
      if params[:search][:query].present?
        @books = Book.available.find(:all,:conditions=>["barcode=? or book_number=?",params[:search][:query],params[:search][:query]])
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html 'book-list', :partial => 'book_list'
      end
    end
    #    if request.post?
    #      unless params[:search][:name] ==""
    #        book = Book.find_by_book_number(params[:search][:name])
    #        error=0
    #        unless book.nil?
    #          error=1 if book.status=="Lost"
    #          error=2 if book.status=="Binding"
    #        else
    #          error=3
    #        end
    #      else
    #        error=4
    #      end
    #      if error==0
    #        redirect_to :action=>'issue_book', :id=>book.id  if book.book_movement_id.nil?
    #        flash[:warn_notice] = "#{t('flash7')}" unless book.book_movement_id.nil?
    #      else
    #        case error
    #        when 1
    #          flash[:warn_notice]= "#{t('flash2')}"
    #        when 2
    #          flash[:warn_notice]= "#{t('flash13')}"
    #        when 3
    #          flash[:warn_notice]= "#{t('flash8')} #{params[:search][:name]}"
    #        else
    #          flash[:warn_notice] = "#{t('flash9')}"
    #        end
    #      end
    #    end
  end

  def renewal
    if params[:book_id]
      @book = Book.find(params[:book_id])
      if @book.nil?
        flash[:warn_notice] = "#{t('flash8')} #{params[:search][:name]}"
      else
        @reserved= BookReservation.find_by_book_id(@book.id)
        @movement = BookMovement.find_by_book_id(@book.id, :conditions=>["status!='Returned' "]) unless @book.book_movement_id.nil?
        flash[:warn_notice] = "#{t('flash10')}" if @book.book_movement_id.nil? and @book.status!='Lost'
        flash[:warn_notice] = "#{t('flash11')}" if @book.status=='Lost'
        redirect_to :action=> 'renewal' and return if(@movement and @book.status=='Lost')
      end
      unless @movement.nil?
        if @movement.user.student?
          @student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",@movement.user.username])
          @issueable = LibraryCardSetting.find_by_course_id(@student.batch.course.id, :conditions=>["student_category_id='#{@student.student_category_id}'"  ]) unless @student.student_category_id.nil?
          @issueable ||= LibraryCardSetting.find_by_course_id(@student.batch.course.id, :conditions=>["student_category_id is NULL"  ])
          @time_period = @issueable.nil? ? 30 : @issueable.time_period
        else
          @time_period = 30
        end
        flash[:warn_notice] = nil
      end
    end
    if request.post?
      if params[:search][:query].present?
        @books=Book.borrowed.find(:all,:conditions=>["barcode=? or book_number=?",params[:search][:query],params[:search][:query]])
      end
      if request.xhr?
        render :update do |page|
          page.replace_html 'book-list', :partial => 'book_list'
        end
      end
    end
  end

  def update_renewal
    @fine = params[:fine] unless params[:fine].nil?
    @renewal = BookMovement.find(params[:id])
    if @renewal.update_attributes(params[:issue])
      BookMovement.update(@renewal.id, :status=>'Renewed')
      @renewal.event.update_attributes(:start_date => @renewal.due_date.to_s, :end_date => @renewal.due_date.to_s)
      unless @fine.nil?
        @student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",@renewal.user.username])
        library_id = FinanceTransactionCategory.find_by_name('Library').id
        FinanceTransaction.create(:amount=>@fine, :category_id=>library_id, :title=>'Library fine', :finance=>@renewal, :payee=>@student,:transaction_date=>FedenaTimeSet.current_time_to_local_time(Time.now).to_date,:payment_mode=>"Cash",:batch_id=>@student.batch_id)
      end
      flash[:notice]="#{t('flash12')}"
    end
    redirect_to :action=>'renewal'
  end
end
