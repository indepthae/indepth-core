require 'dispatcher'
# FedenaOnlineExam

class FedenaOnlineExam
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_online_exam do
      #      ActionController::Base.instance_eval { include Tinymce::Hammer::ControllerMethods }
      #      ActionView::Base.instance_eval { include Tinymce::Hammer::ViewHelpers }
      #      ActionView::Helpers::FormBuilder.instance_eval { include Tinymce::Hammer::BuilderMethods }
      Student.instance_eval { include StudentExtension }
      Employee.instance_eval { has_and_belongs_to_many :online_exam_groups, :join_table=>"online_exam_groups_employees"}
      Batch.instance_eval { 
        has_and_belongs_to_many :online_exam_groups, :join_table=>"online_exam_groups_batches" 
        has_many :online_exam_attendances
        }
      User.send :include, FedenaOnlineExam::UserExtention
      Subject.instance_eval {
        has_and_belongs_to_many :online_exam_groups, :join_table=>"online_exam_groups_subjects"
        has_many :online_exam_questions
      }

    end

  end

  def self.dependency_delete(student)
    OnlineExamAttendance.destroy_all(:student_id => student.id)
  end
  
  def self.application_layout_header
    "layouts/online_exam"
  end

  module UserExtention
    def self.included(base)
      base.class_eval do
        def has_exams_to_evaluate?
          if self.employee
            return true unless self.employee_record.online_exam_groups.empty?
          end
          return false
        end
      end
    end
  end
  
  module StudentExtension
    def self.included(base)
      base.instance_eval do
        has_many :online_exam_attendances
        has_and_belongs_to_many :online_exam_groups, :join_table=>"online_exam_groups_students"
        DependencyHook.make_dependency_hook(:online_batch_exams, :student, :warning_message=> :already_appeared_online_exam ) do
          self.online_exam_exists
        end
        DependencyHook.make_dependency_hook(:fedena_online_exam_dependency, :student, :warning_message=> :already_appeared_online_exam ) do
          self.online_exam_dependencies
        end
      end
    end

    def online_exam_dependencies
      return false if OnlineExamAttendance.find_by_student_id(self.id).present?
      return true
    end

    def available_online_exams
      server_time = Time.now
      server_time_to_gmt = server_time.getgm
      local_tzone_time = server_time
      time_zone = Configuration.find_by_config_key("TimeZone")
      unless time_zone.nil?
        unless time_zone.config_value.nil?
          zone = TimeZone.find_by_id(time_zone.config_value)
          if zone.present?
            if zone.difference_type=="+"
              local_tzone_time = server_time_to_gmt + zone.time_difference
            else
              local_tzone_time = server_time_to_gmt - zone.time_difference
            end
          end
        end
      end
      exams = self.online_exam_groups.all(:joins => :batches, :conditions=> "online_exam_groups.end_date >= '#{local_tzone_time.to_date}' and online_exam_groups.start_date <= '#{local_tzone_time.to_date}' and online_exam_groups.is_published = '1' and batches.id = #{self.batch_id}")
      exams.reject {|e| OnlineExamAttendance.exists?( :student_id => self.id, :online_exam_group_id=>e.id)}
    end

    def online_exam_exists
      online_exam_attendances.select{|o| (o.online_exam_group.batch_ids.include? batch_id) and previous_batch.nil? ? true :((o.online_exam_group.batches.include? previous_batch.batch) ? (o.created_at > previous_batch.created_at) :true)}.empty?
    end
  end

  def self.dependency_check(record,type)
    if type == "permanant"
      if record.class.to_s == "Student"
        return true if OnlineExamAttendance.find_by_student_id(record.id).present?
      end
    end
    return false
  end
end
