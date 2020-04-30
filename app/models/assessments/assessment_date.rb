class AssessmentDate < ActiveRecord::Base
  belongs_to :assessment_group
  belongs_to :batch
  
  validate :check_dates
  
  def check_dates
      errors.add(:start_date, :start_date_cant_be_after_end_date) if start_date > end_date
    end
  
  def self.save_dates(params)
    params[:batch_ids].each do |batch_id|
      dates = self.find_or_initialize_by_batch_id_and_assessment_group_id("start_date"=>params[:start_date],"end_date"=>params[:end_date],"batch_id"=>batch_id,"assessment_group_id"=>params[:assessment_group_id])
      if dates.new_record?
        dates.save
      else
        dates.update_attributes("start_date"=>params[:start_date],"end_date"=>params[:end_date],"batch_id"=>batch_id,"assessment_group_id"=>params[:assessment_group_id])
      end
    end
  end
  
  
end
