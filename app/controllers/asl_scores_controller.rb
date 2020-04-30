class AslScoresController < ApplicationController

  before_filter :login_required
  filter_access_to :all,:except=>[:show,:save_scores]
  filter_access_to [:show,:save_scores],:attribute_check=>true, :load_method => lambda { Exam.find(params[:id]) }


  def show
    @employee_subjects=[]
    @employee_subjects= @current_user.employee_record.subjects.map { |n| n.id} if @current_user.employee?
    @exam = Exam.find params[:id], :include => :subject
    subject = @exam.subject
    config = Configuration.find_or_create_by_config_key('StudentSortMethod')
    if config.config_value == "roll_number"
      @students = subject.batch.is_active ? subject.batch.students.all(:order => "#{Student.sort_order}") : Student.previous_records.all(:conditions=>["batch_students.batch_id=?",subject.batch.id],:order => "soundex(batch_students.roll_number),length(batch_students.roll_number),batch_students.roll_number ASC")
    else
      @students = subject.batch.is_active ? subject.batch.students.all(:order => "#{Student.sort_order}") : Student.previous_records.all(:conditions=>["batch_students.batch_id=?",subject.batch.id],:order => "#{Student.sort_order}")
    end
  end

  def save_scores
    @exam = Exam.find(params[:id])
    @employee_subjects=[]
    @employee_subjects= @current_user.employee_record.subjects.map { |n| n.id} if @current_user.employee?
    @error= false
    params[:asl].each_pair do |student_id, details|
      @asl_score = AslScore.find(:first, :conditions => {:exam_id => @exam.id, :student_id => student_id} )
      if @asl_score.nil?
        if details[:speaking].present? or details[:listening].present?
          if details[:speaking].to_f <= 20.0 and details[:listening].to_f <= 20.0
            AslScore.create do |score|
              score.exam_id          = @exam.id
              score.student_id       = student_id
              score.speaking            = details[:speaking]
              score.listening            = details[:listening]
            end
          else
            @error = true
          end
        end
      else
        save_flag=0
        save_flag = 1 if (details[:speaking].present? or details[:listening].present?)
        if details[:speaking].to_f <= 20.0 and details[:listening].to_f <= 20.0
          if save_flag == 1
            unless @asl_score.update_attributes(details)
              flash[:warn_notice] = "#{t('flash4')}"
              @error = nil
            end
          else
            @asl_score.destroy
          end
        else
          @error = true
        end
      end
    end
    flash[:warn_notice] = "ASL score exceeds maximum marks" if @error == true
    flash[:notice] = "ASL Score Saved" if @error == false
    redirect_to :action=>'show',:id=>@exam.id
  end

end
