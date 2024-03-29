
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
class DescriptiveIndicator < ActiveRecord::Base
  belongs_to    :describable,:polymorphic=>true
  belongs_to    :fa_criteria, :foreign_key=>'describable_id'
  has_many      :assessment_scores
  validates_presence_of :name

  named_scope :co_scholastic,{:conditions=>{:describable_type=>"Observation"}}

  before_destroy :check_dependencies

  default_scope :order=>'sort_order ASC'
  def validate
    errors.add_to_base("Description can't be blank") if self.desc.blank?
  end
  private

  def check_dependencies
    assessment_scores.blank?
  end

end
