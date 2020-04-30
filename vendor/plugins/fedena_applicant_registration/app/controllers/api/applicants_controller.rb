class Api::ApplicantsController < ApiController

  def index
    @xml = Builder::XmlMarkup.new
    @applicants = Applicant.search(params[:search])

    respond_to do |format|
      unless params[:search].present?
        render "single_access_tokens/500.xml"  and return
      else
        format.xml  { render :applicants }
      end
    end
  end
end