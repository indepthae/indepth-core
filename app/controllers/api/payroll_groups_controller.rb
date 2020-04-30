class Api::PayrollGroupsController < ApiController
  lock_with_feature :hr_enhancement
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @payroll_groups = PayrollGroup.ordered

    respond_to do |format|
      format.xml { render :payroll_groups }
    end
  end
end