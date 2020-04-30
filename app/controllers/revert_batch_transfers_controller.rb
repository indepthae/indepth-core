class RevertBatchTransfersController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def index
    @batches = Batch.active
  end

  def list_students
    @batch = Batch.find params[:id]
    include_array=DependencyHook.check_reflections(Student,[{:batch => {:subjects => :assignments}},
        :attendances,:subject_leaves,:students_subjects,{:exam_scores => {:exam => :exam_group}},
        :finance_fees,{:batch_students => {:batch => :course}},{:hostel_fees => :hostel_fee_collection},
        {:transport_fees => :transport_fee_collection},{:online_exam_attendances => {:online_exam_group => [:students,:batches]}},
        {:user => {:poll_votes => :poll_question}}])
    @students = @batch.students.by_first_name.all(:include => 
        include_array.push({:assessment_marks => {:assessment => :assessment_group_batch}, :individual_reports => :generated_report_batch}))
    render :update do |page|
      page.replace_html :students_list, :partial => "students_list"
    end
  end

  def revert_transfer
    @batch = Batch.find params[:id]
    include_array=DependencyHook.check_reflections(Student,[{:batch => {:subjects => :assignments}},:attendances,:subject_leaves,:students_subjects,{:exam_scores => {:exam => :exam_group}},:finance_fees,{:batch_students => {:batch => :course}},{:hostel_fees => :hostel_fee_collection},{:transport_fees => :transport_fee_collection},{:online_exam_attendances => {:online_exam_group => [:students,:batches]}},{:user => {:poll_votes => :poll_question}}])
    unless params[:revert_transfer].nil?
      unless params[:revert_transfer][:students].nil?
        ActiveRecord::Base.transaction do
          students = Student.find(params[:revert_transfer][:students],:include => include_array)
          students.each do |s|
            @error = 1 unless s.revert_batch_transfer_eligiblity.empty?
            if @error == 1
              raise ActiveRecord::Rollback
            end
            prev_batch=s.previous_batch
            unless prev_batch.nil?
              prev_batch.batch.update_attribute(:is_active,true) unless prev_batch.batch.is_active
              s.reset_gradebook_reports # Removing Individual Reports generated without marks
              s.update_attribute(:batch_id,prev_batch.batch_id)
              s.reload
              s.update_attribute(:roll_number,nil)
              prev_batch.destroy
            end
          end
        end 
      end
      unless @error == 1
        render :update do |page|
          page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('reverted_successfully')}</p>"
          page.replace_html :students_list, :text => ""
        end
      else
        @students = @batch.students.by_first_name.all(:include => include_array)
        render :update do |page|
          page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('revert_halted')}</p>"
          page.replace_html :students_list, :partial => "students_list"
        end
      end
    else
      @students = @batch.students.by_first_name.all(:include => include_array)
      render :update do |page|
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('select_at_least_one_student')}</p>"
        page.replace_html :students_list, :partial => "students_list"
      end
    end
  end

end
