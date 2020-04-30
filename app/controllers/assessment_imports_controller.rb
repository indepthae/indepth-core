class AssessmentImportsController < ApplicationController
  before_filter :login_required

  require 'lib/override_errors'
  helper OverrideErrors


  def imports
    @assessment_group = AssessmentGroup.find params[:assessment_group_id]
    @batch = Batch.find params[:batch_id]
    @imports = AssessmentScoreImport.all(:conditions => {:assessment_group_id => @assessment_group.id, :batch_id => @batch.id }, :order => 'created_at DESC')
    @import = AssessmentScoreImport.new(:assessment_group_id => @assessment_group.id, :batch_id => @batch.id)
    @agb = @assessment_group.assessment_group_batches.first(:conditions => {:batch_id => @batch.id})
  end

  def create
    @import = AssessmentScoreImport.new(params[:import])
    if params[:import][:attachment].present?
      if @import.save
        flash[:notice] = t('import_is_in_queue')
        redirect_to :action => 'imports', :assessment_group_id => @import.assessment_group_id, :batch_id => @import.batch_id
      else
        errors = true
      end
    else
      @import.add_empty_file_error
      errors = true
    end
    if errors
      @assessment_group = AssessmentGroup.find @import.assessment_group_id
      @batch = Batch.find @import.batch_id
      @imports = AssessmentScoreImport.all(:conditions => {:assessment_group_id => @assessment_group.id, :batch_id => @batch.id }, :order => 'created_at DESC')
      @agb = @assessment_group.assessment_group_batches.first(:conditions => {:batch_id => @batch.id})
      render :imports
    end
  end

  def import_form
    batch = Batch.find params[:batch_id]
    assessment_group = AssessmentGroup.find params[:assessment_group_id]
    data = AssessmentScoreImportService.new.download_form(batch.id, assessment_group.id)
    send_data(data, :type => 'text/csv; charset=utf-8; header=present', :filename => "assessment_import_#{batch.full_name}_#{assessment_group.name}.csv")
  end

  def show_log
    @import = AssessmentScoreImport.find params[:import_id]
  end

end
