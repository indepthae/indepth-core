# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module Gradebook
  module Components
    class ActivityScoreFactory < ComponentFactory
        
      def process_and_build_components
        activity_sets = Models::Collection.new
        activity_groups.each do |activity_group|
          agb = activity_group.assessment_group_batches.to_a.find{|agb| (agb.batch_id == batch.id) and agb.marks_added?}
          next unless agb
          activity_sets.push build_activity_set(activity_group, agb)
        end
          
        activity_sets
      end
        
      ##
      # returns activity set component
      # params:
      # => activity_group
      # => agb (`assessment_group_batch` object of the batch)
      def build_activity_set(activity_group, agb)
        scores = Models::Collection.new
        activities = Models::Collection.new
        activity_group.assessment_activity_profile.assessment_activities.each do |activity|
          activity_component = new_activity(activity)
          activities.push activity_component
          scores.push new_score(agb, activity, activity_component)
        end
        
        return Models::ActivitySet.new(
          :name => activity_group.display_name,
          :profile_name => activity_group.assessment_activity_profile.name ,
          :activities => activities,
          :scores => scores,
          :term_name => term_name(activity_group),
          :code =>activity_group.code
        )
      end
        
      ##
      # returns activity component for activity object passed
      def new_activity(activity)
        Models::Activity.new(:name => activity.name, :description => activity.description)
      end
        
      ##
      # returns score object for each activity
      # params:
      # => agb (`assessment_group_batch` object of the batch)
      # => activity (activity object)
      # => activity_component (component object of activity)
      def new_score(agb, activity, activity_component)
        converted_mark = student.converted_assessment_marks.detect{|cam| cam.markable_id == activity.id and 
            cam.markable_type == 'AssessmentActivity' and cam.assessment_group_batch_id == agb.id}
        Models::Score.new(:activity => activity_component, :grade => converted_mark.try(:grade)|| '-')
      end
        
      private
        
      attr_accessor :reportable, :student
        
    end
  end
end
