class Api::HostelsController < ApiController

  def index
    @xml = Builder::XmlMarkup.new
    @hostels = Hostel.search(params[:search])

    respond_to do |format|
      unless params[:search].present?
        render "single_access_tokens/500.xml"  and return
      else
        format.xml  { render :hostels }
      end
    end
  end
end
