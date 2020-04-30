require 'rubygems'
require 'uri'
require 'yaml'
require 'json'
require 'git'
require 'net/http'
module FedenaUpdate
  cds_settings=YAML.load_file("#{RAILS_ROOT}/vendor/plugins/cds_adapter/config/cds_settings.yml")
  SERVER=cds_settings['settings']['server_name']
  FEDENA_NAME=cds_settings['settings']['fedena_name']
  def self.fedena_updates_check
    settings_file=YAML.load(File.open("vendor/plugins/acts_as_multi_school/config/multischool_settings.yml"))
    school_count=settings_file['settings']['max_school_count']
    license_key=settings_file['settings']['license_key']
    installed_id=settings_file['settings']['installed_id']
    res = Net::HTTP.get_response(URI.parse(URI.encode("#{SERVER}/release_projects/client_plan_updates_check?license_key=#{license_key}&license_count=#{school_count}&installed_id=#{installed_id}")))
    response_msg= JSON.parse(res.body)
    if response_msg['release_msg']!=nil
      update_details={'release_message'=>response_msg['release_msg'],'release_note'=>response_msg['release_note']}
      File.open("#{RAILS_ROOT}/vendor/plugins/acts_as_multi_school/config/update_details.yml","wb"){|f| f.write update_details.to_yaml}
    end
    if response_msg['status']==true
      return true
    else
      return false
    end
  end

  def self.update_fedena
    logger = Logger.new("#{RAILS_ROOT}/log/fedena_cds_update.log")
    logger.info "=========Updation Starting==========="
    path="#{RAILS_ROOT}/vendor/plugins/acts_as_multi_school/config/multischool_settings.yml"
    settings_file=YAML.load(File.open(path))
    license_key=settings_file['settings']['license_key']
    installed_id=settings_file['settings']['installed_id']
    res = Net::HTTP.get_response(URI.parse(URI.encode("#{SERVER}/release_projects/updates_script_generation?license_key=#{license_key}&installed_id=#{installed_id}")))
    response_msg= JSON.parse(res.body)
    if response_msg['status']==true
      installation_scripts=response_msg['script']
      error=false
      installation_scripts.each do |script|
        if script['name']==FEDENA_NAME
          root_path=RAILS_ROOT
          script['name']=root_path.split("/").last
          installation_path=(root_path.split("/")-root_path.split("/").last.to_a).join("/")
        else
          installation_path="#{RAILS_ROOT}/vendor/plugins"
          if script['name']=="fedena_bbb"
            script['name']="fedena_bigbluebutton"
          end
          if script['name']=="fedena_exception_notification"
            script['name']="exception_notification"
          end
        end
        if File.directory?("#{installation_path}/#{script['name']}")
          begin
            git=Git.open("#{installation_path}/#{script['name']}", {})
            git.pull
          rescue Git::GitExecuteError =>e
            logger.info "=====#{script['name']} git pull failed===="
            logger.info  e
            error=true
          end
          logger.info "==========#{script['name']} Updated============"
        else
          begin
            Git.clone("#{script['url']}", "#{installation_path}/#{script['name']}")
            logger.info  "==========#{script['name']} Created============"
          rescue Git::GitExecuteError =>e
            logger.info  "=====#{script['name']} git clone failed===="
            logger.info  e
            error=true
          end
        end
      end
      unless error
        logger.info  "========Installation Started==========="
        if response_msg['is_saas_enabled']
          logger.info  "========SaaS Installation==========="
          resp=logger.info system("rake fedena:install_saas RAILS_ENV=#{RAILS_ENV}")
        else
          logger.info  "========MultiSchool Installation==========="
          resp=logger.info system("rake fedena:install_multischool RAILS_ENV=#{RAILS_ENV}")
        end
        if resp
          logger.info  "========Installation Completed==========="
          logger.info  "========Settings file updating==========="
          settings_file['settings']['organization_details']['school_stats']=response_msg['school_stats']
          File.open(path, "wb") { |s| s.write settings_file.to_yaml }
          logger.info  "========Settings file updated==========="
          logger.info "========Restarting==========="
          resp=system("touch tmp/restart.txt")
        end
        if resp
          logger.info "========Restart Successfully==========="
          logger.info  "========School Seeds Stared==========="
          log_name="log/school_seed_log_#{Time.now.strftime("%d%b%Y")}"
          resp=logger.info system("nohup rake fedena:seed_schools RAILS_ENV=#{RAILS_ENV}  >> #{log_name} &")
        end
        if resp==true
          logger.info "========#{log_name} Created==========="
          logger.info "========School seeds on progress==========="
          return true
        else
          logger.info "========Updation failed==========="
          return false
        end
      else
        return false
      end
    else
      return false
    end

  end

  def self.update_status
    logger = Logger.new("#{RAILS_ROOT}/log/fedena_cds_update.log")
    settings_file=YAML.load(File.open("vendor/plugins/acts_as_multi_school/config/multischool_settings.yml"))
    school_count=settings_file['settings']['max_school_count']
    license_key=settings_file['settings']['license_key']
    installed_id=settings_file['settings']['installed_id']
    res = Net::HTTP.get_response(URI.parse(URI.encode("#{SERVER}/release_projects/client_plan_updates_check?license_key=#{license_key}&license_count=#{school_count}&installed_id=#{installed_id}&updated=#{true}")))
    response_msg= JSON.parse(res.body)
    if response_msg['status']==true
      settings_file['settings']['version']=response_msg['release_msg']
      File.open("vendor/plugins/acts_as_multi_school/config/multischool_settings.yml","wb"){|f| f.write settings_file.to_yaml}
      logger.info "==========Successfully Updated==========="
      return false
    else
      return true
    end
  end

end


