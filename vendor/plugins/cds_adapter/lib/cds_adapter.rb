module CdsAdapter

  cds_settings=YAML.load_file("#{RAILS_ROOT}/vendor/plugins/cds_adapter/config/cds_settings.yml")
  SERVER=cds_settings['settings']['server_name']

  def self.attach_overrides
    Dispatcher.to_prepare :cds_adapter do
      ::MultiSchoolController.instance_eval { include MultiSchoolControllerCds }
      ::SchoolDomain.instance_eval { include SchoolDomainCds }
      ::School.instance_eval { include SchoolCds }
      ::SchoolsController.instance_eval { before_filter :check_for_fedena_updates ,:only=>[:index,:show,:profile,:list_schools] }
      ::SchoolsController.instance_eval { include SchoolsControllerCds}
      ::AdminUsersController.instance_eval { include AdminUsersControllerCds }
      if (ClientSchoolGroup rescue false)
        ::ClientSchoolGroup.instance_eval{include ClientSchoolGroupCds}
      end
    end
  end

  module MultiSchoolControllerCds
    def check_for_fedena_updates
      session[:update]=FedenaUpdate.fedena_updates_check
    end
  end

  module SchoolDomainCds

    def send_domain_names
      settings_file=YAML.load(File.open("vendor/plugins/acts_as_multi_school/config/multischool_settings.yml"))
      school_count=settings_file['settings']['max_school_count']
      license_key=settings_file['settings']['license_key']
      installed_id=settings_file['settings']['installed_id']
      school_name=linkable.name.gsub(" ","_")
      res=Net::HTTP.get_response(URI.parse(URI.encode("#{SERVER}/release_projects/school_domain_name_updation?license_key=#{license_key}&license_count=#{school_count}&installed_id=#{installed_id}&domain_names=#{linkable.school_domains.collect(&:domain).join(',')}&school_name=#{school_name}&school_id=#{linkable.id}")))
      response_msg= JSON.parse(res.body)
      if response_msg['status']==true
        status=true
      else
        status=false
        errors.add_to_base("Error occured.")
      end
      return status
    end

  end

  module SchoolCds

    def self.included (base)
      base.instance_eval {after_create :school_creation}
      base.instance_eval {after_update :school_updation}
    end

    def school_creation
      res=cds_school_changes
      response_msg= JSON.parse(res.body)
      if response_msg['status']==true
        status=true
      else
        status=false
        errors.add_to_base("Maximum school exceeds")
        raise ActiveRecord::Rollback
      end
      return status
    end

    def school_updation
      res=cds_school_changes
      response_msg= JSON.parse(res.body)
      if response_msg['status']==true
        status=true
      else
        status=false
        errors.add_to_base("Updation failed")
        raise ActiveRecord::Rollback
      end
      return status
    end

    def school_deletion
      settings_file=YAML.load(File.open("vendor/plugins/acts_as_multi_school/config/multischool_settings.yml"))
      school_count=settings_file['settings']['max_school_count']
      license_key=settings_file['settings']['license_key']
      installed_id=settings_file['settings']['installed_id']
      res = Net::HTTP.get_response(URI.parse(URI.encode("#{SERVER}/release_projects/client_school_deletion?license_key=#{license_key}&license_count=#{school_count}&installed_id=#{installed_id}&school_id=#{id}")))
      response_msg= JSON.parse(res.body)
      if response_msg['status']==true
        status=true
      else
        status=false
        errors.add_to_base("Error occured contact administrator")
      end
      return status
    end

    private

    def cds_school_changes
      settings_file=YAML.load(File.open("vendor/plugins/acts_as_multi_school/config/multischool_settings.yml"))
      school_count=settings_file['settings']['max_school_count']
      license_key=settings_file['settings']['license_key']
      installed_id=settings_file['settings']['installed_id']
      school_name=name.gsub(" ","_")
      res = Net::HTTP.get_response(URI.parse(URI.encode("#{SERVER}/release_projects/client_school_creation?license_key=#{license_key}&license_count=#{school_count}&installed_id=#{installed_id}&domain_names=#{school_domains.collect(&:domain)}&school_name=#{school_name}&school_id=#{id}")))
      return res
    end

  end

  module ClientSchoolGroupCds

    def self.included (base)
      base.instance_eval {before_save :client_creation}
    end

    def client_creation
      res=license_status
      response_msg= JSON.parse(res.body)
      if response_msg['status']==true
        status=true
      else
        status=false
        self.errors.add(:license_count,"Maximum number of School Licenses exceeded.")
      end
      return status
    end

    def license_status
      settings_file=YAML.load(File.open("vendor/plugins/acts_as_multi_school/config/multischool_settings.yml"))
      total_created_license=ClientSchoolGroup.active.sum(:license_count,:conditions=>["id !=?", self.try(:id)|| 0 ])
      total_created_license+=self.license_count
      license_key=settings_file['settings']['license_key']
      installed_id=settings_file['settings']['installed_id']
      res = Net::HTTP.get_response(URI.parse(URI.encode("#{SERVER}/release_projects/saas_license_validation_on_client_school_group?license_key=#{license_key}&total_created_license=#{total_created_license}&installed_id=#{installed_id}")))
      return res
    end
  
  end

  module AdminUsersControllerCds

    def self.included (base)
      if (ClientSchoolGroup rescue false)
        base.instance_eval { before_filter :check_for_fedena_updates ,:only=>[:dashboard] }
      else
        base.instance_eval { before_filter :check_for_fedena_updates ,:only=>[:index,:show] }
      end
    end

    def update_details
      if session[:update]==true
        if  File.exist? "#{RAILS_ROOT}/vendor/plugins/acts_as_multi_school/config/update_details.yml"
          update_details=YAML.load(File.open("#{RAILS_ROOT}/vendor/plugins/acts_as_multi_school/config/update_details.yml"))
          @release_msg=update_details['release_message']
          @release_note=update_details['release_note']
        end
      end
    end

    def install_updates
      if session[:update]==true
        response=FedenaUpdate.update_fedena
        if response==true
          session[:update]=FedenaUpdate.update_status
          if  File.exist? "#{RAILS_ROOT}/vendor/plugins/acts_as_multi_school/config/update_details.yml"
            File.delete("#{RAILS_ROOT}/vendor/plugins/acts_as_multi_school/config/update_details.yml")
          end
          flash[:notice]= "Successfully Updated"
        else
          flash[:warn_notice]= "Updation Failed"
        end
      end
      render(:update) do|page|
        if (ClientSchoolGroup rescue false)
          page.redirect_to :controller => 'admin_users', :action => 'dashboard'
        else
          page.redirect_to :controller => 'schools', :action => 'index'
        end
      end
    end
  end

  module SchoolsControllerCds
    def self.included(base)
      base.alias_method_chain :destroy,:cds_destroy
      base.alias_method_chain :add_domain,:cds_add_domain
      base.alias_method_chain :delete_domain,:cds_delete_domain
    end

    def destroy_with_cds_destroy
      MultiSchool.current_school = @school
      error=false
      ActiveRecord::Base.transaction do
        if @school.soft_delete
          unless @school.school_deletion
            error=true
            raise ActiveRecord::Rollback
          end
        else
          error=true
        end
      end
      unless error
        flash[:notice]="School deleted successfully"
        respond_to do |format|
          format.html { redirect_to(schools_url) }
          format.xml  { head :ok }
        end
      else
        respond_to do |format|
          format.html {render :action => "show",:id=>@school.id  }
          format.xml  { render :xml => @school.errors, :status => :unprocessable_entity }
        end
      end
    end

    def add_domain_with_cds_add_domain
      @domain = @school.school_domains.new(params[:add_domain])
      render :update do |page|
        error=false
        SchoolDomain.transaction do
          if @domain.save
            unless @domain.send_domain_names
              raise ActiveRecord::Rollback 
              error=true
            else
              error=false
            end
          else
            error=true
          end
        end
        unless error
          message="Domain added."
          page.insert_html :bottom, 'domains', :partial=>"added_domain"
        else
          message = "Unable to add domain - #{@domain.errors.full_messages.join(',')}"
        end

        page.replace_html 'message_div', message
      end
    end

    def delete_domain_with_cds_delete_domain
      domain = @school.school_domains.find_by_id(params[:domain_id])
      error=false
      SchoolDomain.transaction do
        destroyed = domain.destroy if domain
        if destroyed
          unless domain.send_domain_names
            raise ActiveRecord::Rollback
            error=true
          else
            error=false
          end
        else
          error=true
        end
      end
      unless error
        @message="Domain deleted"
        raise ActiveRecord::Rollback unless domain.send_domain_names
      else
        @message="Could not delete domain - #{domain.errors.full_messages.join(',')}"
      end
      render :partial=>'domain'
    end
  end

end

require 'cds_adapter/fedena_update'

