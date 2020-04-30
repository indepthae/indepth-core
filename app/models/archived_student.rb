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

class ArchivedStudent < ActiveRecord::Base

  include CceReportMod

  belongs_to :country
  belongs_to :batch
  belongs_to :student_category
  belongs_to :nationality, :class_name => 'Country'
  belongs_to :user
  #has_many :archived_guardians, :foreign_key => 'ward_id', :dependent => :destroy
  has_many   :archived_guardians, :foreign_key => 'ward_id', :primary_key=>:sibling_id, :dependent => :destroy
  has_one :immediate_contact
  has_one :advance_fee_wallet , :primary_key=>:former_id, :foreign_key=>'student_id'

  has_many   :students_subjects, :primary_key=>:former_id, :foreign_key=>'student_id'
  has_many   :assessment_marks, :primary_key=>:former_id, :foreign_key=>'student_id'
  has_many   :converted_assessment_marks, :primary_key=>:former_id, :foreign_key=>'student_id'
  has_many   :individual_reports, :primary_key=>:former_id, :foreign_key=>'student_id'
  has_many   :subjects ,:through => :students_subjects

  has_many   :cce_reports, :primary_key=>:former_id, :foreign_key=>'student_id'
  has_many   :assessment_scores, :primary_key=>:former_id, :foreign_key=>'student_id'
  has_many   :exam_scores, :primary_key=>:former_id, :foreign_key=>'student_id'
  has_many   :student_additional_details, :primary_key=>:former_id, :foreign_key=>'student_id'
  has_many   :icse_reports,:primary_key=>:former_id,  :foreign_key=>'student_id'
  has_many   :student_coscholastic_remarks,:primary_key=>:former_id, :foreign_key=>'student_id'
  has_many   :student_coscholastic_remark_copies,:primary_key=>:former_id, :foreign_key=>'student_id'
  named_scope :name_or_admssn_no_as, lambda{|query|{:conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ? OR admission_no LIKE ? OR concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? OR concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ?","#{query}%","#{query}%", "#{query}%", "#{query}%", "#{query}%", "#{query}%"]}}
  named_scope :student_name_as, lambda{|query|{:conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ? OR concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? OR concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ?","#{query}%", "#{query}%", "#{query}%", "#{query}%", "#{query}%"]}}
  before_save :is_active_false
  before_destroy :destroy_transfer_certificate

  #has_and_belongs_to_many :graduated_batches, :class_name => 'Batch', :join_table => 'batch_students',:foreign_key => 'student_id' ,:finder_sql =>'SELECT * FROM `batches`,`archived_students`  INNER JOIN `batch_students` ON `batches`.id = `batch_students`.batch_id WHERE (`batch_students`.student_id = `archived_students`.former_id )'

  has_attached_file :photo,
    :styles => {
    :thumb=> "100x100#",
    :small  => "150x150>"},
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension"

  def is_active_false
    unless self.is_active==0
      self.is_active=0
    end
  end
  
  def fetch_school_report(grb_id)
    IndividualReport.find(:all,:conditions=>["generated_report_batch_id = ? and student_id = ?", grb_id, self.s_id]).first
  end
  
  def destroy_transfer_certificate
    record = TcTemplateRecord.find_by_student_id self.id
    record.destroy if record
  end
  
  def self.sort_order 
    config = Configuration.get_sort_order_config_value
    sort_order = "first_name ASC" if config.config_value == "first_name"
    sort_order = "last_name ASC" if config.config_value == "last_name"
    sort_order = "soundex(admission_no),length(admission_no),admission_no ASC" if config.config_value == "admission_no"
    sort_order = "soundex(archived_students.roll_number),length(archived_students.roll_number),archived_students.roll_number ASC" if config.config_value == "roll_number"
    return sort_order
  end
  
  def s_id
    former_id
  end
  
  def full_batch_course_name
    "#{self.batch_in_context.course.course_name} - #{self.batch_in_context.name}"
  end

  def gender_as_text
    self.gender == 'm' ? 'Male' : 'Female'
  end

  def first_and_last_name
    "#{first_name} #{last_name}"
  end

  def full_name
    "#{first_name} #{middle_name} #{last_name}"
  end

  def full_course_name
    "#{self.batch.course.course_name} - #{self.batch.name}"
  end

  def full_address
    "#{address_line1} #{address_line2} #{city} #{state} #{pin_code}"
  end

  def father_name
    father_name=self.archived_guardians.first(:conditions=>{:relation=>"father"})
    father_name.present? ? father_name.full_name : nil
  end
  
  def in_format_dob
    format_date(date_of_birth,:format=>:short)
  end

  def mother_name
    mother_name=self.archived_guardians.first(:conditions=>{:relation=>"mother"})
    mother_name.present? ? mother_name.full_name : nil
  end

  def guardian_name
    father=self.archived_guardians.first(:conditions=>{:relation=>"father"})
    unless father.present?
      guardian=self.archived_guardians.first(:conditions=>["relation != 'father' and relation != 'mother'"])
      if guardian.present?
        return "#{guardian.full_name}"+" (#{guardian.translated_relation})"
      else
        return
      end
    end
    return father.full_name

    guardian_name=self.archived_guardians.first()
    guardian_name.present? ? "#{guardian_name.full_name}"+" (#{guardian_name.translated_relation})" : ""
  end

  def finance_fee_by_date(date)
    FinanceFee.find_by_fee_collection_id_and_student_id(date.id,self.former_id)
  end

  def roll_number_in_context
    config = Configuration.find_by_config_key("EnableRollNumber")
    if config.present? and config.config_value == "1"
      if attributes.include? "roll_number_in_context_id"
        return roll_number_in_context_id.present? ? roll_number_in_context_id : "-"
      end
      if batch_id == batch_in_context_id
        roll_number.present? ? roll_number : "-"
      else
        prev_data = BatchStudent.last(:conditions=>{:batch_id=>batch_in_context_id,:student_id=>former_id})
        prev_data.roll_number.present? ? prev_data.roll_number : "-"
      end
    end
  end

  def to_student
    archived_student_attributes = self.attributes
    archived_student_attributes.delete "id"
    archived_student_attributes.delete "former_id"
    archived_student_attributes.delete "status_description"
    archived_student_attributes.delete "date_of_leaving"
    archived_student_attributes.delete "former_has_paid_fees"
    archived_student_attributes.delete "former_has_paid_fees_for_batch"
    archived_student_attributes.delete "created_at"
    archived_student_attributes.delete "roll_number"
    Student.new(archived_student_attributes)
  end

  def immediate_contact
    unless self.immediate_contact_id.nil?
      ArchivedGuardian.find_by_former_id(self.immediate_contact_id) unless student_siblings.present?
    end
  end

  def all_batches
    self.graduated_batches + self.batch.to_a
  end

  def graduated_batches
    # SELECT * FROM `batches` INNER JOIN `batch_students` ON `batches`.id = `batch_students`.batch_id
    Batch.find(:all,:conditions=> ["batch_students.student_id = #{former_id.to_i}"], :joins =>'INNER JOIN batch_students ON batches.id = batch_students.batch_id' )
  end
  
  def graduated_cce_batches
    self.all_batches.map { |b| b if b.cce_enabled?}.reject{|a| a.nil? }
  end
  
  def graduated_icse_batches
    self.all_batches.map { |b| b if b.icse_enabled?}.reject{|a| a.nil? }
  end
  
  def graduated_normal_batches
    self.all_batches.map { |b| b if b.normal_enabled?}.reject{|a| a.nil? }
  end
  
  def all_batches
    self.graduated_batches + self.batch.to_a
  end

  def additional_detail(additional_field)
    StudentAdditionalDetail.find_by_additional_field_id_and_student_id(additional_field,self.former_id)
  end

  def has_retaken_exam(subject_id)
    retaken_exams = PreviousExamScore.find_all_by_student_id(self.former_id)
    if retaken_exams.empty?
      return false
    else
      exams = Exam.find_all_by_id(retaken_exams.collect(&:exam_id))
      if exams.collect(&:subject_id).include?(subject_id)
        return true
      end
      return false
    end

  end
  def siblings
    @siblings ||= (self.class.find_all_by_sibling_id(sibling_id) - [self])
  end
  
  def student_siblings
    @siblings ||= (Student.find_by_sibling_id(sibling_id))
  end
  
  def name_with_suffix
    value = Fedena.sort_order_config
    if value == "admission_no"
      return "#{self.full_name} (#{self.admission_no})&#x200E;" 
    elsif value == "roll_number" 
      if self.roll_number.present? 
        return "#{self.full_name} (#{self.roll_number})&#x200E;" 
      else
        return "#{self.full_name} (-)&#x200E;"
      end
    else
      if Configuration.enabled_roll_number?
        return "#{self.full_name} (#{self.roll_number})&#x200E;" if self.roll_number.present? 
        return "#{self.full_name} (-)&#x200E;" unless self.roll_number.present? 
      else
        return "#{self.full_name} (#{self.admission_no})&#x200E;"
      end
    end
  end

  def self.former_students_details(parameters)
    sort_order=parameters[:sort_order]
    former_students=parameters[:former_students]
    unless former_students.nil?
      if sort_order.nil?
        students=ArchivedStudent.all(:select=>"first_name,last_name,middle_name,admission_no,roll_number,admission_date,status_description,CONCAT(courses.code,'-',batches.name) as batch_name,courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,archived_students.id as student_id,gender,archived_students.created_at,archived_students.date_of_leaving",:joins=>[:batch=>:course],:conditions=>{:archived_students=>{:date_of_leaving=>former_students[:from].to_date.beginning_of_day..former_students[:to].to_date.end_of_day}},:order=>'first_name ASC')
      else
        students=ArchivedStudent.all(:select=>"first_name,last_name,middle_name,admission_no,roll_number,admission_date,status_description,CONCAT(courses.code,'-',batches.name) as batch_name,courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,archived_students.id as student_id,gender,archived_students.created_at,archived_students.date_of_leaving",:joins=>[:batch=>:course],:conditions=>{:archived_students=>{:date_of_leaving=>former_students[:from].to_date.beginning_of_day..former_students[:to].to_date.end_of_day}},:order=>sort_order)
      end
    else
      if sort_order.nil?
        students=ArchivedStudent.all(:select=>"first_name,last_name,middle_name,admission_no,roll_number,admission_date,status_description,CONCAT(courses.code,'-',batches.name) as batch_name,courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,archived_students.id as student_id,gender,archived_students.created_at,archived_students.date_of_leaving",:joins=>[:batch=>:course],:conditions=>{:archived_students=>{:date_of_leaving=> Date.today.beginning_of_day..Date.today.end_of_day}},:order=>'first_name ASC')
      else
        students=ArchivedStudent.all(:select=>"first_name,last_name,middle_name,admission_no,roll_number,admission_date,status_description,CONCAT(courses.code,'-',batches.name) as batch_name,courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,archived_students.id as student_id,gender,archived_students.created_at,archived_students.date_of_leaving",:joins=>[:batch=>:course],:conditions=>{:archived_students=>{:date_of_leaving=> Date.today.beginning_of_day..Date.today.end_of_day}},:order=>sort_order)
      end
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('admission_no') }","#{t('admission_date') }","#{t('leaving_date') }","#{t('batch_name')}","#{t('course_name')}","#{t('gender')}","#{t("reason_for_leaving")}"]
    col_heads.insert(2,t('roll_no')) if Configuration.enabled_roll_number?
    data << col_heads
    students.each_with_index do |s,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{s.full_name}"
      col << s.roll_number if Configuration.enabled_roll_number?
      col<< "#{s.admission_no}"
      col<< "#{format_date(s.admission_date)}"
      col<< "#{format_date(s.date_of_leaving.to_date)}"
      col<< "#{s.batch_name}"
      col<< "#{s.course_name} #{s.code} #{s.section_name}"
      col<< "#{s.gender.downcase=='m' ? t('m') : t('f')}"
      col<< "#{s.status_description}"
      col=col.flatten
      data<< col
    end
    return data
  end

  def self.archived_student_revert(archived_student_id)
    student=Student.new
    ActiveRecord::Base.transaction do
      archived_student = ArchivedStudent.find archived_student_id
      old_id = archived_student.former_id.to_s.dup
      has_paid_fees=archived_student.former_has_paid_fees.to_s.dup
      has_paid_fees_for_batch=archived_student.former_has_paid_fees_for_batch.to_s.dup
      archived_student_attributes = archived_student.attributes
      archived_student_attributes.delete "id"
      archived_student_attributes.delete "former_id"
      archived_student_attributes.delete "status_description"
      archived_student_attributes.delete "date_of_leaving"
      archived_student_attributes.delete "former_has_paid_fees"
      archived_student_attributes.delete "former_has_paid_fees_for_batch"
      archived_student_attributes.delete "created_at"
      archived_student_attributes.delete "roll_number"
      sibling_id=archived_student_attributes["sibling_id"].present? ? archived_student_attributes["sibling_id"] : old_id
      student = Student.new(archived_student_attributes)
      student.has_paid_fees=has_paid_fees
      student.has_paid_fees_for_batch=has_paid_fees_for_batch
      student.archived = true
      student.photo = archived_student.photo if archived_student.photo.file?
      if student.save
        sib_stud=Student.find_by_id(sibling_id)
        unless sib_stud.present?
          sibling_id=old_id
        end
        sql = "update students set id = #{old_id},sibling_id = #{sibling_id} where id = #{student.id}"
        ActiveRecord::Base.connection.execute(sql)
        student=Student.find(old_id)
        student.batch.activate
        student.batch.course.activate
        if student.all_siblings.present?
          unless student.immediate_contact.present? and student.immediate_contact.user.present?
            student.immediate_contact_id=nil
            student.send(:update_without_callbacks)
          end
        else
          archived_guardians=archived_student.archived_guardians
          archived_guardians.each do |a_g|
            former_user_id = a_g.attributes["former_user_id"].to_s.dup
            former_id=a_g.attributes["former_id"].to_s.dup
            archived_guardian_attributes = a_g.attributes
            archived_guardian_attributes.delete "former_user_id"
            archived_guardian_attributes.delete "former_id"
            archived_guardian_attributes.delete "id"
            guardian = Guardian.new(archived_guardian_attributes)
            guardian.user_id=former_user_id
            guardian.photo = a_g.photo if a_g.photo.file?
            if guardian.save
              a_g.destroy
            end
            if student.immediate_contact_id.to_s==former_id
              student.immediate_contact_id=guardian.id
              student.send(:update_without_callbacks)
            end
          end
        end
        archived_student.destroy
      else
        raise ActiveRecord::Rollback
      end
    end
    return student
  end
  
  def ef_father
    archived_guardians.to_a.find{|x| x.relation =~ /father/i}
  end
  
  
  def ef_mother
    archived_guardians.to_a.find{|x| x.relation =~ /mother/i}
  end
  
  
  def ef_immediate_contact
    archived_guardians.to_a.find{|x| x.former_id  == self.immediate_contact_id}
  end
  
  def finance_fee_by_date(date, inc_fee_assoc = {})
    # NOTE::
    # readonly false is used to allow update on the returned object
    FinanceFee.last(
      :conditions => ["fee_collection_id = ? AND student_id = ? AND (ffc.fee_account_id IS NULL OR fa.is_deleted = false)", date.id, self.former_id],
      :joins => "INNER JOIN finance_fee_collections ffc ON ffc.id = finance_fees.fee_collection_id
                  LEFT JOIN fee_accounts fa ON fa.id = ffc.fee_account_id",
      :include => { :finance_transactions => :transaction_ledger }.merge(inc_fee_assoc),
      :readonly => false
    )
  end
  
  def fees_list_by_batch(batch_id=self.batch_id, order=nil, date=nil)
    batch=Batch.find(batch_id)
    unless order.present?
      order = "finance_fees.balance DESC"
    end
    trans_date = date.present? ? date : Date.today
    FinanceFeeCollection.find(:all,
      :joins => " LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id
                 INNER JOIN finance_fees  ON finance_fees.fee_collection_id = finance_fee_collections.id                 
                  LEFT JOIN finance_transactions 
                         ON finance_transactions.finance_id = finance_fees.id AND finance_transactions.finance_type ='FinanceFee'
                 INNER JOIN batches ON  batches.id = #{batch_id}",
      :conditions => "(fa.id IS NULL OR fa.is_deleted = false) AND
                    finance_fees.student_id='#{self.former_id}' and
                    finance_fee_collections.is_deleted = #{false} and
                    finance_fees.batch_id = #{batch_id}",
      :select => "finance_fee_collections.* ,batches.name AS batch_name, finance_fees.is_paid,
                  finance_fees.balance, finance_fees.batch_id, finance_fees.balance_fine AS balance_fine, finance_fees.is_fine_waiver AS is_fine_waiver,
                  MAX(finance_transactions.transaction_date) AS last_transaction_date,
                  SUM(finance_transactions.amount) AS paid_amount,
                  (SELECT IFNULL(SUM(IF(finance_transactions.description = 'fine_amount_included',
                                        finance_transactions.fine_amount, 
                                0)),0)
                     FROM finance_transactions finance_transactions
                    WHERE finance_transactions.finance_id=finance_fees.id AND 
                          finance_transactions.finance_type='FinanceFee'
                  ) AS automatic_fine_paid,
                  (IFNULL((finance_fees.particular_total - finance_fees.discount_amount),
                               finance_fees.balance + 
                               (SELECT IFNULL(SUM(finance_transactions.amount - 
                                                  finance_transactions.fine_amount),
                                             0)
                                  FROM finance_transactions
                                 WHERE finance_transactions.finance_id=finance_fees.id AND 
                                       finance_transactions.finance_type='FinanceFee'
                               ) - 
                               IF(finance_fees.tax_enabled,finance_fees.tax_amount,0)
                               ) 
                              ) AS actual_amount,
                 (SELECT is_amount   FROM fine_rules ffr WHERE ffr.fine_id = finance_fee_collections.fine_id AND   
                    ffr.created_at <= finance_fee_collections.created_at AND   ffr.fine_days <= DATEDIFF(   COALESCE(Date('#{trans_date}'),CURDATE()),  
                    finance_fee_collections.due_date )   ORDER BY ffr.fine_days DESC LIMIT 1) AS is_amount,
                 (SELECT fine_amount FROM fine_rules ffr WHERE ffr.fine_id = finance_fee_collections.fine_id AND   
                    ffr.created_at <= finance_fee_collections.created_at AND   ffr.fine_days <= DATEDIFF(   COALESCE(Date('#{trans_date}'),CURDATE()),  
                    finance_fee_collections.due_date )   ORDER BY ffr.fine_days DESC LIMIT 1) AS fine_amount",
      :group => "finance_fees.id",
      :order => order
    )
  end
  
  
end
