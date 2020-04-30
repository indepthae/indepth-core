class AddUniqueIndexToApplicantRegNo < ActiveRecord::Migration
  def self.up
    modify_reg_no
    add_index :applicants, [:reg_no, :school_id], :unique => true
  end

  def self.down
    remove_index :applicants, [:reg_no, :school_id], :unique => true
  end
  
  private
  
  def self.modify_reg_no
    log = Logger.new("log/applicant_no_change.log")
    log.info("================STARTED ON #{Time.now}============")
    school_ids = Applicant.find_by_sql("SELECT distinct school_id as s_id FROM `applicants` GROUP BY reg_no,school_id HAVING count(reg_no)>1;")
    log.info("================Total Schools #{school_ids.count}============")
    school_ids.each do |school_id|
      log.info("================School #{school_id.s_id} STARTED ON #{Time.now}============")
      MultiSchool.current_school= School.find_by_id(school_id.s_id)
      duplicate_reg_nos = Applicant.find(:all,:select=>'distinct reg_no as reg',:group=>"reg_no",:having=>"count(reg_no)>1")
      log.info("==============DUPLICATE NUMBERS=======#{duplicate_reg_nos.collect(&:reg)}============================================")
      duplicate_reg_nos.each do |register_no|
        applicants = Applicant.find_all_by_reg_no(register_no.reg)
        applicants.each_with_index do |applicant, i|
          unless i == 0
            applicant.reg_no = applicant_number
            applicant.send(:update_without_callbacks)
            log.info("==Applicant #{applicant.first_name} with REG Number #{register_no.reg} Changed to #{applicant.reg_no}==")
          end
        end
      end
      log.info("================School #{school_id.s_id} COMPLETED ON #{Time.now}============")
      log.info("=============================================================================")
    end
  end
 
  def self.applicant_number
    last_applicant = Applicant.find(:first,:conditions=>["reg_no is not NULL"], :order=>"CONVERT(reg_no,unsigned) DESC")
    if last_applicant
      last_reg_no = last_applicant.reg_no.to_i
    else
      last_reg_no = 0
    end
    reg_no = last_reg_no.next
  end
  
end
