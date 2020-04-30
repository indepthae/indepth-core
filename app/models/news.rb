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

class News < ActiveRecord::Base
  include Notifier
  belongs_to :author, :class_name => 'User'
  has_many :comments, :class_name => 'NewsComment'
  has_many :news_attachments,:dependent=> :destroy
  accepts_nested_attributes_for :news_attachments  , :allow_destroy => true ,:reject_if => lambda { |a| a[:attachment].blank? }, :allow_destroy => true
  after_save :reload_news_bar
  before_destroy :delete_redactors
  after_destroy :reload_news_bar
  after_save :update_redactor
  after_create :send_notification_to_all_users
  attr_accessor :redactor_to_update, :redactor_to_delete

  validates_presence_of :title, :content

  default_scope :order => 'created_at DESC'

  cattr_reader :per_page 
  xss_terminate :except => [:content]
  @@per_page = 12

  def self.get_latest
    News.find(:all, :limit => 3)
  end

  def reload_news_bar
    ActionController::Base.new.expire_fragment(News.cache_fragment_name)
  end

  def self.cache_fragment_name
    'News_latest_fragment'
  end

  def update_redactor
    RedactorUpload.update_redactors(self.redactor_to_update,self.redactor_to_delete)
  end

  def delete_redactors
    RedactorUpload.delete_after_create(self.content)
  end
  def comments_count
    current_user = Authorization.current_user
    is_moderator = current_user.admin? || current_user.privileges.include?(Privilege.find_by_name('ManageNews'))
    if is_moderator 
          @comments = self.comments.count
    else
         @comments = self.comments.approved_comments.count
    end
  end
  
  def send_notification_to_all_users
    news_id = id
    recipient_ids = "all"
    content = t('new_news_published')
    links = {:target=>'show_news',:target_value=>news_id}
    inform(recipient_ids,content,'News',links)
  end

end
