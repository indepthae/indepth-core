class EiopSetting < ActiveRecord::Base
  belongs_to :course

  def self.save_criteria(params)
    params.each do |key,value|
      entry = EiopSetting.find_by_course_id(value["course_id"])
      if entry.present?
        entry.update_attributes(:course_id=>value["course_id"],:grade_point=>value["grade_point"],:pass_text=>value["pass_text"],:eiop_text=>value["eiop_text"])
      else
        EiopSetting.create(:course_id=>value["course_id"],:grade_point=>value["grade_point"],:pass_text=>value["pass_text"],:eiop_text=>value["eiop_text"])
      end
    end
  end
  
end
