require 'dispatcher'
module FedenaFormBuilder
  def self.attach_overrides
    ::FedenaSetting.instance_eval { include FedenaSettingExtension }
    ::ActiveRecord::Base.instance_eval { extend ActiveRecord }
    Dispatcher.to_prepare :fedena_form_builder do
      ::User.instance_eval { include UserExtension }
      ::Searchkick.instance_eval { extend SearchkickExtension } if FedenaSetting.elasticsearch_enabled?
    end
  end

  module UserExtension
    def self.included(base)
      base.instance_eval do
        has_many :form_templates,:class_name => 'FormTemplate',:dependent=>:destroy
        has_many :form_submissions,:class_name => 'FormSubmission',:dependent=>:destroy
        has_and_belongs_to_many :forms, :class_name => 'Form'
        has_and_belongs_to_many :form_targets, :class_name => 'Form', :join_table => 'form_targets_users'
      end

      base.class_eval do

      end
    end
  end

  module FedenaSettingExtension
    def self.included(base)
      base.class_eval do
        def self.elasticsearch_enabled?
          File.exist?("#{File.dirname(__FILE__)}/../../config/elasticsearch.yml")
        end
      end
    end
  end

  module SearchkickExtension
    def self.extended(base)
      base.class_eval do
        def self.client
          @client ||= Elasticsearch::Client.new :hosts=> [
            { :host => ElasticSearchConfig.host,#'localhost',
              :port => ElasticSearchConfig.port,#'9200' ,
              :user => ElasticSearchConfig.user,#'USERNAME',
              :password => ElasticSearchConfig.password #'PASSWORD',
              #              :scheme => 'https'
            }]
        end
      end
    end
  end

  module ElasticSearchConfig

    # this allows us to lazily instantiate the configuration by reading it in when it needs to be accessed
    class << self
      # if a method is called on the class, attempt to look it up in the config array
      def method_missing(meth, *args, &block)
        if args.empty? && block.nil?
          elastic_search_config[meth.to_s]
        end
      end


      private
      def elastic_search_config

        @elastic_config ||= YAML.load(ERB.new(File.read(File.join(::Rails.root, 'vendor/plugins/fedena_form_builder','config', 'elasticsearch.yml'))).result)[::Rails.env]
      rescue
        warn('something wrong in fields yml file.')
        {}
      end
    end
  end
end

module ActiveRecord
    def find_all_for_searchkick_reindex(options = {})
      raise "You can't specify an order, it's forced to be #{batch_order}" if options[:order]
      raise "You can't specify a limit, it's forced to be the batch_size"  if options[:limit]

      start = options.delete(:start).to_i
      batch_size = options.delete(:batch_size) || 1000

      with_scope(:find => options.merge(:order => batch_order, :limit => batch_size)) do
        records = find_every(:conditions => [ "#{table_name}.#{primary_key} >= ?", start ])

        while records.any?
          yield records

          break if records.size < batch_size
          records = find_every(:conditions => [ "#{table_name}.#{primary_key} > ?", records.last.id ])
        end
      end
    end

    def find_one_without_school(id, options={})
      conditions = " AND (#{sanitize_sql(options[:conditions])})" if options[:conditions]
      options.update :conditions => "#{quoted_table_name}.#{connection.quote_column_name(primary_key)} = #{quote_value(id,columns_hash[primary_key])}#{conditions}"

      # Use find_every(options).first since the primary key condition
      # already ensures we have a single record. Using find_initial adds
      # a superfluous :limit => 1.
      if result = find_every(options).first
        result
      else
        raise RecordNotFound, "Couldn't find #{name} with ID=#{id}#{conditions}"
      end
    end
  end
