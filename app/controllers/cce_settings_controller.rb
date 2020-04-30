#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class CceSettingsController < ApplicationController
  before_filter :login_required
  filter_access_to :all,:attribute_check=>true, :load_method => lambda { current_user }
  
  def index
  end

  def basic
  end

  def scholastic
  end

  def co_scholastic
  end

  def fa_settings
    @fa_setting = Configuration.find_or_create_by_config_key("CceFaType")
    if request.put?
      cce_fa_type = params[:configuration][:config_value]
      @fa_setting = Configuration.set_value("CceFaType", cce_fa_type)
      flash[:notice] = "FA settings has been successfully saved"
      redirect_to :action => 'fa_settings'
    end
  end
  
end
