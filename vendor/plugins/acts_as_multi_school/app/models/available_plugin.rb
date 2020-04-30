class AvailablePlugin < ActiveRecord::Base
  serialize :plugins
  belongs_to :associated, :polymorphic => true

  before_save :check_plugins
  before_update :flush_plugin_cache, :if => Proc.new { |ap| ap.associated_type=="School"  }
  
  def flush_plugin_cache
      ['available_plugin','available_plugins'].each do |plugin|
        cahce_key_name = [plugin,"/#{self.associated_id}/", 'School']
        Configuration.uncache_it(cahce_key_name)
      end
    end

  def check_plugins
    self.plugins = [] if self.plugins.nil?
  end

  def after_initialize
    check_plugins
    plugins_will_change!
  end

end
