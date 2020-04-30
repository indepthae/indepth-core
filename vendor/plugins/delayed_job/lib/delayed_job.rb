require 'active_support'
require 'rush'
require File.dirname(__FILE__) + '/delayed/message_sending'
require File.dirname(__FILE__) + '/delayed/performable_method'
require File.dirname(__FILE__) + '/delayed/backend/base'
require File.dirname(__FILE__) + '/delayed/worker'
require File.dirname(__FILE__) + '/delayed/manager'
require File.dirname(__FILE__) + '/delayed/deserialization_error'
require File.dirname(__FILE__) + '/delayed/railtie' if defined?(::Rails::Railtie)

Object.send(:include, Delayed::MessageSending)   
Module.send(:include, Delayed::MessageSending::ClassMethods)

if defined?(Merb::Plugins)
  Merb::Plugins.add_rakefiles File.dirname(__FILE__) / 'delayed' / 'tasks'
end

module Delayed
  # enable auto_scale if you want DJ to spin a worker when there's a
  # new job to be done, and kill it when there's nothing else to do
  mattr_accessor :auto_scale
  self.auto_scale = true

  # the auto_scale_manager is the class that knows how to scale workers
  # up and down
  mattr_accessor :auto_scale_manager
  self.auto_scale_manager = :local

end