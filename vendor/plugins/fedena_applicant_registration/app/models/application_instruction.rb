class ApplicationInstruction < ActiveRecord::Base
  belongs_to :registration_course

  validates_uniqueness_of :registration_course_id, :allow_nil=>true

  attr_accessor :redactor_to_update, :redactor_to_delete

  before_destroy :delete_redactors
  after_save :update_redactor

  xss_terminate :except => [ :description ]

  def update_redactor
    RedactorUpload.update_redactors(self.redactor_to_update,self.redactor_to_delete)
  end

  def delete_redactors
    #RedactorUpload.delete_after_create(self.description)
  end
end
