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

class TcTemplateFootersController < ApplicationController
  before_filter :login_required
  before_filter :template_presence_required
  before_filter :find_template
  filter_access_to :all
  check_request_fingerprint :edit
  def edit
    @footer = TcTemplateFieldFooter.get_footer_settings(@current_template)
    if request.post?
      @error_messages = []
      ActiveRecord::Base.transaction do  
        result = TcTemplateFieldFooter.check_and_save(params[:footer_config])
        if result.count > 0
          result.each do |entry|
            entry.errors.full_messages.each {|ent| @error_messages << ent}
          end
          @footer = TcTemplateFieldFooter.submitted_values(params[:footer_config])
          flash.now[:warn_notice] = "#{@error_messages}"
          raise ActiveRecord::Rollback
          render "edit" and return
        else
          flash[:notice] = "#{t('flash_msg8')}"
          redirect_to :action => "edit"  and return
        end
      end
    end
  end
  
  private
  
  def template_presence_required
    unless TcTemplateVersion.current
      TcTemplateVersion.initialize_first_template
    end
  end
  
  def find_template
    @current_template = TcTemplateVersion.current
  end
end
