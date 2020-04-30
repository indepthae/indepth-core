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
class BookMovement < ActiveRecord::Base
  belongs_to :user
  belongs_to :book
  belongs_to :financial_year
  validates_presence_of :user_id, :book_id, :issue_date, :due_date
  has_one :event, :as=> :origin,:dependent=>:destroy
  has_many :finance_transactions ,:as=>:finance
  before_destroy :update_book_status
  before_create :set_financial_year

  def set_financial_year
    self.financial_year_id = FinancialYear.current_financial_year_id
  end

  def get_student_id
    return Student.first(:conditions => ["admission_no LIKE BINARY(?)",self.user.username]).id
  end

  def get_employee_id
    return  Employee.first(:conditions => ["employee_number LIKE BINARY(?)",self.user.username]).id
  end

  def fee_table
  end

  def update_book_status
    book = self.book
    if book.book_movement_id == self.id
      book.update_attributes(:book_movement_id =>nil,:status=>'Available')
    end
  end
  def payee_name
    if user
    "#{user.full_name}(#{user.username})"
    else
      "#{t('user_deleted')}"
    end
  end
  def self.movement_log(parameters)
    sort_order=parameters[:sort_order]
    book_log = parameters[:book_log]    
    book_log_type = parameters[:book_log_type]
    book_log_start_date = parameters[:book_log_start_date]
    book_log_end_date = parameters[:book_log_end_date]
    if book_log.nil?
      if sort_order.nil?
        conditions = ["book_movements.issue_date= ? ",Date.today]
        order = 'due_date ASC'
      else
        conditions = ["book_movements.issue_date= ? ",Date.today]
        order = sort_order
      end
    else
      if sort_order.nil?
        if book_log_type=="Due date"
          conditions = ["book_movements.due_date BETWEEN ? and ? ",book_log_start_date.to_date,book_log_end_date.to_date]
          order = 'due_date ASC'
        else
          conditions = ["book_movements.issue_date BETWEEN ? and ? ",book_log_start_date.to_date,book_log_end_date.to_date]
          order = 'due_date ASC'
        end
      else
        if book_log_type =="Due date"
          conditions = ["book_movements.due_date BETWEEN ? and ? ",book_log_start_date.to_date,book_log_end_date.to_date]
          order = sort_order
        else
          conditions= ["book_movements.issue_date BETWEEN ? and ? ",book_log_start_date.to_date,book_log_end_date.to_date]
          order = sort_order
        end
      end
    end     
    log = BookMovement.find(:all,:select=>"students.id as student_id,students.admission_no,archived_students.id as archived_student_id,batches.name as batch_name,batches.name as batch_name,
                                              employees.employee_number ,employees.id as employee_id,employee_departments.name as employee_department_name,
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
      :order=>order)
    data=[]
    col_heads=["#{t('no_text')}","#{t('book_number')}","#{t('title')}","#{t('library.borrowed_by') }","#{t('employee/admission number')}","#{t('library.batch_or_department') }","#{t('status') }","#{t('issue_date')}","#{t('due_date')}"]
    data << col_heads
    log.each_with_index do |s,i|
        col=[]
        col<< "#{i+1}"
        col<< "#{s.book_number}"
        col<< "#{s.title}"
        if s.student? && s.is_deleted?
          col<< "#{s.first_name} #{s.last_name} "
          col<< " #{s.username}"
        elsif s.student?
          col<< "#{s.first_name} #{s.last_name} "
          col<< "#{s.admission_no}"
        else
          col<< "#{s.first_name} #{s.last_name}"
          col<< "#{s.employee_number}"
        end
        if s.student?
          col<< "#{s.course_code}-#{s.batch_name}"
        else
          col<< "#{s.employee_department_name}"
        end
        col<< "#{s.status}"
        col<< "#{format_date(s.issue_date)}"
        col<< "#{format_date(s.due_date)}"
        col=col.flatten
        data<< col
      end
    return data
  end
end
