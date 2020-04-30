class CourseTranscriptSetting < ActiveRecord::Base
  belongs_to :course
  
  def self.get_course_transcript_setting(course_id,value)
    course = Course.find(course_id)
    setting = course.course_transcript_setting
    if setting.present?
      setting.update_attributes(:show_grade=>value["show_grade"], :show_percentage=>value["show_percentage"])
    else
      setting=CourseTranscriptSetting.create(:course_id=>course_id.to_i, :show_grade=>value["show_grade"], :show_percentage=>value["show_percentage"])
    end
  end
end
