class AppFrame < ActiveRecord::Base
  require 'uri'
  serialize :privilege_list
  validates_presence_of :name,:client_id,:privilege_list,:link
  validates_format_of :link, :with => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix

  belongs_to :client, :class_name =>  'Oauth2::Provider::OauthClient', :foreign_key => :client_id

  #  after_save :clear_app_menu_cache
  #  after_destroy :clear_app_menu_cache

  def validate
    !!URI.parse(link)
  rescue URI::InvalidURIError
    errors.add('link', :should_be_a_valid_url)
  end

  HUMANIZED_COLUMNS = {:link => "URL"}

  #  def clear_app_menu_cache
  #
  #  end

  def self.human_attribute_name(attribute)
    HUMANIZED_COLUMNS[attribute.to_sym] || super
  end
end
