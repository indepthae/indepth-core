class ReminderAttachmentRelation < ActiveRecord::Base
  belongs_to :reminder
  belongs_to :reminder_attachment,:dependent=>:destroy
  accepts_nested_attributes_for :reminder_attachment
  validates_uniqueness_of :reminder_id, :scope => [:reminder_attachment_id]
end
