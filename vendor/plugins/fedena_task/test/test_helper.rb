require 'rubygems'
require 'active_support'
require 'active_support/test_case'
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "./../../../../config/environment")
require File.dirname(__FILE__) + "/factories"
require 'test_help'

class ActiveSupport::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  # fixtures :all

  private
  def assert_invalid(object, msg = nil)
    msg ||= "#{object.class} is valid where it should be invalid."
    assert ! object.valid?, msg
  end

  def login_as(user)
   @request.session[:user_id] = user.id
   @request.session[:current_school_id] = Thread.current[:current_school_id] = user.school_id
   @request.session[:current_school_name] =  user.school.nil? ? "" : user.school.school_name
 end
 
end


