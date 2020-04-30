module SchoolStats

  def self.config &block
    module_eval(&block) if block_given?
  end

  def self.entity name,&block
    data_entity = DataEntity.new(:name=>name)
    block.call(data_entity)
    data_entity
  end

  def self.load_config
    DataEntity.reset
  end

  module InvalidStats
  end
  
  class StatsError < StandardError
  end

  class EntityNotFound < StatsError
    include InvalidStats
  end

  EXCEPTIONS = [ActiveRecord::StatementInvalid,InvalidStats]

  def self.school_stats_en
    if File.exists?("#{Rails.root}/vendor/plugins/acts_as_multi_school/config/school_stats_en.yml")
      YAML::load(File.open("#{Rails.root}/vendor/plugins/acts_as_multi_school/config/school_stats_en.yml"))
    else
      {'en'=>{}}
    end
  end

end

require 'school_stats/child_entity'
require 'school_stats/data_entity'
require 'school_stats/data_row'
#require 'school_stats/stats_config'
