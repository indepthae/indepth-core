class ApplicantAddlFieldValue < ActiveRecord::Base
  #validates_presence_of :option
  belongs_to :applicant_addl_field

  named_scope :active,{:conditions=>{:is_active=>true}}
  
  def default_field
    option
  end
end
