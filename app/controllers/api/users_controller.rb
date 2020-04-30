class Api::UsersController < ApiController

  def show
    @xml = Builder::XmlMarkup.new
    @user = User.active.first(:conditions => ["username LIKE BINARY(?)",params[:id]])
    if @user.parent?
      @wards=@user.guardian_entry.wards.all(:conditions=>["immediate_contact_id=?", @user.guardian_entry.id])
    end
    @privileges = @user.privileges.all.map(&:description)
    
    respond_to do |format|
      unless @user.nil?
        format.xml  { render :user }
      else
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      end
    end
    
  end
  
end
