class ApplicantPreviousData < ActiveRecord::Base
  belongs_to :applicant
  
  def validate
    mandatory_attributes = self.applicant.m_p_attr
    if mandatory_attributes.present?
      mandatory_attributes.split(", ").each do|m|
        self.applicant.errors.add_to_base("#{ApplicantPreviousData.human_attribute_name(m)} can't be blank") unless self.send(m).present?
      end
    end
  end
end
