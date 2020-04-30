# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class DerivedAssessmentGroupsAssociation < ActiveRecord::Base
  belongs_to :derived_assessment_group
  belongs_to :assessment_group
  accepts_nested_attributes_for :assessment_group
  attr_accessible :derived_assessment_group_id, :assessment_group_id, :assessment_group_attributes, :priority
end
