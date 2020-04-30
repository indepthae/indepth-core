class FormBuilderController  < ApplicationController
  before_filter :login_required
  filter_access_to :all
  
  def index
    
  end

end
