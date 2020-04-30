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
class AssessmentScore < ActiveRecord::Base
  belongs_to :student
  belongs_to :descriptive_indicator
  belongs_to :subject

  named_scope :co_scholastic, {:conditions=>{:cce_exam_category_id=>nil}}
  named_scope :scholastic, {:conditions=>['assessment_scores.cce_exam_category_id > 0']}
  #  belongs_to :cce_grade
  
  def self.save_fa_scores(grade_hash,batch,subject,cce_exam_category)
    AssessmentScore.transaction do
      grade_hash.each do |key,val|
        if val['formula'] == "1"
          val["students"].each_pair do |student_id,scores_hash|
            scores_hash["scores"].each_pair do |di,point|
              if point.to_f <= val["max_marks"].to_f
                student=Student.find(student_id)
                score = student.assessment_score_for(di, subject.id,cce_exam_category.id, batch.id)
                unless point.blank?
                  score.grade_points=point.to_f
                  score.batch_id=batch.id
                  unless score.save
                    @err=1
                  end
                else
                  unless score.destroy
                    @err=1
                  end
                end
              else
                @err=1
              end
            end
          end
        elsif val['formula'] == "2"
          val["students"].each_pair do |student_id,scores_hash|
            if scores_hash["scores"].present? and scores_hash["scores"].values.inject { |a, b| a.to_f + b.to_f }.to_f <= val["max_marks"].to_f
              scores_hash["scores"].each_pair do |di,point|
  
                student=Student.find(student_id)
                score = student.assessment_score_for(di, subject.id,cce_exam_category.id, batch.id)
                unless point.blank?
                  score.grade_points=point.to_f
                  score.batch_id=batch.id
                  unless score.save
                    @err=1
                  end
                else
                  unless score.destroy
                    @err=1
                  end
                end
  
              end
            else
              @err=1
            end
          end
  
        end
      end
      return (@err || 0)
    end
  end
end
