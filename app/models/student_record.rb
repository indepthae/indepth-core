class StudentRecord < ActiveRecord::Base
  #  VALID_IMAGE_TYPES = ['image/gif', 'image/png','image/jpeg', 'image/jpg']
  #  validates_attachment_content_type :photo, :content_type =>VALID_IMAGE_TYPES,
  #    :message=>'Image can only be GIF, PNG, JPG',:if=> Proc.new { |p| !p.photo_file_name.blank? }
  #  validates_attachment_size :photo, :less_than => 512000,\
  #    :message=>'must be less than 500 KB.',:if=> Proc.new { |p| p.photo_file_name_changed? }

  has_many :record_addl_attachments,:dependent=>:destroy
  belongs_to :record,:foreign_key=>'additional_field_id'
  belongs_to :student
  belongs_to :batch
  validates_uniqueness_of :additional_info,:scope=>[:student_id,:batch_id,:additional_field_id]
  accepts_nested_attributes_for :record_addl_attachments, :allow_destroy => true , :reject_if => lambda { |a| a.values.all?(&:blank?) }




  def self.get_records(student_id,batch_id,records_ids)
    StudentRecord.find_all_by_student_id_and_batch_id_and_additional_field_id(student_id,batch_id,records_ids)
  end

  def get_student_record_csv_report_details(batch_details, students_details, rg_id)
    rg=''
    FasterCSV.generate do |csv|
     @rec_det_count={}
      if rg_id.present?
        # @record_details = Record.all(:conditions=>["record_group_id=?",rg_id],:order=>"record_group_id ASC")
        @record_details = Record.all(:conditions=>["record_group_id=? and input_type not in('attachment')",rg_id],:order=>"record_group_id ASC")
        rg=RecordGroup.find(rg_id)
        @rec_det_count[rg_id]=Record.count(:conditions=>["record_group_id=?",rg_id])
        @rec_grp=RecordGroup.find_all_by_id(rg_id).map{|rec| [rec.name,rec.is_active]}
      else
        # @record_details = Record.all(:joins=>"inner join record_batch_assignments on record_batch_assignments.record_group_id = records.record_group_id", :conditions => ["record_batch_assignments.batch_id =?",batch_details.id] ,:order=> "records.record_group_id, records.priority")
        @record_details = Record.all(:joins=>"inner join record_batch_assignments on record_batch_assignments.record_group_id = records.record_group_id", :conditions => ["record_batch_assignments.batch_id =? and input_type not in('attachment')",batch_details.id] ,:order=> "records.record_group_id, records.priority")
        @rec_det_count= Record.count(:joins=>"inner join record_batch_assignments on record_batch_assignments.record_group_id = records.record_group_id", :conditions => ["input_type not in(?)and record_batch_assignments.batch_id =?",["attachment"],batch_details.id] ,:group=> "records.record_group_id")
        rec_keys=@rec_det_count.keys
        @rec_grp=RecordGroup.find_all_by_id(rec_keys).map{|rec| [rec.name,rec.is_active]}
      end
      #====student record group names in first row====
      cols=[]
      cols <<"" <<"" <<""
      rec_grp_val=[]
      @rec_grp.each do |rec|
        rec_grp_val<<rec[0]
      end
      index=0
      @rec_det_count.values.each do |num|
        cols << "#{rec_grp_val.at(index)}"
        index= index +1
        rec_counter=1
        while rec_counter<num
          cols << ""
          rec_counter=rec_counter+1
        end
      end
      csv << cols
      #====student record names - header in second row====
      cols=[]
      cols <<  "#{t('admission_no')}"
      cols <<  "#{t('student_name')}"
      cols <<  "#{t('batch_name')}"
      @record_details.each do |rd|
        if rd.suffix.present?
          cols << "#{rd.name}(#{rd.suffix})"
        else
          cols << "#{rd.name}"
        end
      end
      csv << cols
      #====Student value in csv====
      students_details.each do |student|
          if rg_id.present?
            @student_records=student.student_records.all(:select=>"distinct s.first_name, rg.name rg_name,rg.id rg_id,r.*,student_records.*,ra.priority o_p",:conditions=>["(student_records.batch_id=? and student_records.additional_field_id IN (?) and r.input_type!='attachment') or (student_records.additional_info != '' and student_records.batch_id=? and student_records.additional_field_id IN (?) and r.input_type!='attachment')",batch_details.id,rg.records.collect(&:id),batch_details.id,rg.records.collect(&:id)],:joins=>"inner join students s on s.id=student_records.student_id inner join records r on r.id=student_records.additional_field_id inner join record_groups rg on rg.id=r.record_group_id inner join batches b on b.id=student_records.batch_id inner join courses c on c.id=b.course_id inner join record_assignments ra on ra.record_group_id =rg.id and ra.course_id=c.id",:order=>"o_p asc").group_by(&:rg_id)
            # @student_records=student.student_records.all(:select=>"distinct s.first_name, rg.name rg_name,r.*,student_records.*,ra.priority o_p",:conditions=>["(student_records.batch_id=? and student_records.additional_field_id IN (?)) or (student_records.additional_info != '' and student_records.batch_id=? and student_records.additional_field_id IN (?))",batch_details.id,rg.records.collect(&:id),batch_details.id,rg.records.collect(&:id)],:joins=>"inner join students s on s.id=student_records.student_id inner join records r on r.id=student_records.additional_field_id inner join record_groups rg on rg.id=r.record_group_id inner join batches b on b.id=student_records.batch_id inner join courses c on c.id=b.course_id inner join record_assignments ra on ra.record_group_id =rg.id and ra.course_id=c.id",:order=>"o_p asc").group_by(&:rg_name)
          else
            @student_records=student.student_records.all(:select=>"distinct s.first_name, rg.name rg_name, rg.id rg_id,r.*,student_records.*",:conditions=>["(r.input_type!='attachment' and student_records.batch_id=?) or (r.input_type!='attachment' and student_records.additional_info != '' and student_records.batch_id=?)",batch_details.id,batch_details.id],:joins=>"inner join students s on s.id=student_records.student_id inner join records r on r.id=student_records.additional_field_id inner join record_groups rg on rg.id=r.record_group_id",:order=>"rg_id asc").group_by(&:rg_id)
          end
          cols=[]
          fullname= student.first_name
          cols << "#{student.admission_no}"
          cols << "#{student.full_name}"
          cols << "#{batch_details.full_name}"
          if @student_records.present?
            rd_counter=0
            student_rec_sort= @student_records.keys.map{|i| i.to_i}
            student_rec_sort.each do |key|
              sr=@student_records[key.to_s]
              sr.each do |record|
                while((record.additional_field_id!=@record_details.at(rd_counter).id) && (rd_counter< @record_details.length))
                   cols<<""
                   rd_counter=rd_counter+1
                end
                if record.input_type == "date"
                  cols << format_date(record.additional_info)
                else
                  cols << "#{record.additional_info}"
                end
                rd_counter=rd_counter+1
              end
            end
          end
        csv << cols
      end
    end
  end

end
