class PushNotification
  attr_accessor :data, :user_ids, :send_to_all, :school_id, :options

  def initialize (data, user_ids, options={}, school_id=nil)
    @data = data
    @user_ids = user_ids
    @options = options
    @send_to_all = options[:send_to_all]
    @school_id = school_id || MultiSchool.current_school.id
    clean_data(data)
  end
  
  def clean_data (arg)
    arg.each do |key,val|
      if val.is_a? String
        arg[key] = val.gsub(':', ' ')
      elsif val.is_a? Hash
        arg[key] = clean_data (val)
      end
    end
    arg
  end

  def self.push_notify (opts)
    return unless PushSetting.available?
    payload = new(opts[:data], opts[:user_ids], opts[:options] || {}, opts[:school_id])
    Delayed::Job.enqueue(payload, :queue=> 'push_notification')
  end

  def perform
  end

  class PushSetting < ActiveRecord::Base
    self.table_name = 'mobile_push_settings'

    def self.available?
      table_exists? && MultiSchool.current_school.connect_app.present? && MultiSchool.current_school.connect_app.push_available?
    end
  end

  class ConnectApp < ActiveRecord::Base
    self.table_name = 'connect_apps'

    belongs_to :owner, :polymorphic => true
    belongs_to :group_app, :class_name => 'PushNotification::ConnectApp'
    has_one :push_setting, :class_name => 'PushNotification::PushSetting'

    def app_type
      @app_type ||= if is_standalone?
                      'standalone_app'
                    elsif is_grouped?
                      'grouped_app'
                    else
                      'member_app'
                    end
    end

    def push_available?
      if app_type == 'member_app'
        group_app.present? && group_app.push_setting.present?
      else
        push_setting.present?
      end
    end
  end

  ::School.instance_eval do
    has_one :connect_app, :class_name => 'PushNotification::ConnectApp', :as => :owner
  end

end
