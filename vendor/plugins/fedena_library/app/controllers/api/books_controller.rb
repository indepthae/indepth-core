class Api::BooksController < ApiController

  def index
    @xml = Builder::XmlMarkup.new
    @books = Book.search(params[:search])

    respond_to do |format|
      unless params[:search].present?
        render "single_access_tokens/500.xml"  and return
      else
        format.xml  { render :books }
      end
    end
  end
end
