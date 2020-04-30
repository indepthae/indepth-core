class Remark < ActiveRecord::Base
  belongs_to :remark_setting,:foreign_key=>'target_id',:class_name=>"RemarkSetting"
  has_many :remark_parameters,:dependent=>:destroy
  belongs_to :student
  belongs_to :batch
  belongs_to :user,:foreign_key=>'submitted_by'
  accepts_nested_attributes_for :remark_parameters, :allow_destroy => true
  
  class << self
    
    def fetch_student_remarks(params)
      data_hash ||= Hash.new
      data_hash[:parameters] = params
      current_user = Authorization.current_user
      student = unless params[:archived_id].present?
        (current_user.student? ? current_user.student_record : Student.find(params[:student_id],:include => {:batch => :course}))
      else
        ArchivedStudent.find(params[:archived_id],:include => {:batch => :course})
      end
      data_hash[:student] = student
      student_id = (params[:archived_id].present? ? student.former_id : student.id)
      target = RemarkSetting.find_by_target('custom_remark')
      unless params[:history].present?
        remarks = all(:conditions => { :student_id => student_id, :target_id => target.id, :batch_id => student.batch_id }, :order => "updated_at DESC")
      else
        batches = Batch.all(:select => "DISTINCT batches.*", :joins => "LEFT OUTER JOIN `batch_students` ON batch_students.batch_id = batches.id", :conditions => ["batch_students.student_id = ?", student_id], :include => :course, :order => "batch_students.id DESC")
        batches.unshift(student.batch)
        batch_ids = batches.collect(&:id)
        remarks = all(:conditions => { :student_id => student_id, :target_id => target.id, :batch_id => batch_ids.uniq }, :include => :batch, :order => "updated_at DESC").group_by(&:batch_id)
      end
      data_hash[:batches] = batches.try(:uniq)
      data_hash[:remarks] = remarks
      case params[:report_format_type]
      when "csv"
        [send("fetch_student_remarks_csv",data_hash), data_hash]
      when "pdf"
        return data_hash
      end
    end
  
    def fetch_student_remarks_csv(data_hash)
      csv_string = FasterCSV.generate do |csv|
        csv << [t('remark').upcase]
        csv << ["#{t('name')} : #{data_hash[:student].full_name}"]
        csv << ["#{t('admission_number')} : #{data_hash[:student].admission_no}"]
        csv << ["#{(data_hash[:parameters][:history].present? ? t('current_batch') : t('batch'))} : #{data_hash[:student].batch.complete_name}"]
        csv << ["#{t('roll_no')} : #{(data_hash[:student].roll_number.present? ? data_hash[:student].roll_number : "-")}"] if data_hash[:student].batch.roll_number_enabled?
        csv << []
        csv << [t('remarked_by'), t('remark_subject'), t('remark'), t('last_updated')]
        unless data_hash[:batches].present? 
          data_hash[:remarks].each do |val|
            row = [(val.remarked_by.present? ? val.remarked_by : '-')]
            row << (val.remark_subject.present? ? val.remark_subject : '-')
            row << (val.remark_body.present? ? val.remark_body : '-')
            row << "#{format_date(val.updated_at, :format => :long_date)}"
            csv << row
          end
        else
          data_hash[:batches].each_with_index do |batch, i|
            csv << [] unless i == 0
            csv << ["#{t('batch')} : #{batch.complete_name}"]
            remarks = data_hash[:remarks][batch.id]
            if remarks.present?
              remarks.each do |val|
                row = [(val.remarked_by.present? ? val.remarked_by : '-')]
                row << (val.remark_subject.present? ? val.remark_subject : '-')
                row << (val.remark_body.present? ? val.remark_body : '-')
                row << "#{format_date(val.updated_at, :format => :long_date)}"
                csv << row
              end
            else
              csv << [t('no_remarks_were_added')]
            end
          end
        end
      end
      csv_string
    end
  end
    
end
