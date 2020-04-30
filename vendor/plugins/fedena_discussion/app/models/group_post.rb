class GroupPost < ActiveRecord::Base
  belongs_to :group
  belongs_to :user

  has_many :group_post_comments, :dependent => :destroy
  has_many :group_files, :dependent => :destroy

  accepts_nested_attributes_for :group_files
  
  validates_presence_of :post_title, :message =>:cant_be_blank
  validates_length_of :post_title, :maximum => 30
  validates_presence_of :post_body, :message =>:cant_be_blank

  after_create :notify_members

  def can_delete_his_own_post?(user_in_question)
    user_in_question==self.user
  end

  def notify_members
    member_ids = self.group.members.collect(&:id)
    member_ids.delete(user_id)
    body = "<b>#{self.user.full_name}</b> #{t('posted')} <b>#{self.group.group_name}</b>"
    links = {:target=>'open_discussion',:target_param=>'group_id',:target_value=>self.group.id}
    inform(member_ids,body,'Discussion',links)
  end
  
end