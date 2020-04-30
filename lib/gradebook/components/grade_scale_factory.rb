module Gradebook
  module Components
    class GradeScaleFactory < ComponentFactory
      def process_and_build_components
        scales = new_collection
        return scales unless grade_scale_enabled?
        
        if is_assessment_group?
          if reportable.grade_set_id.present?
            description = is_activity_assessment_group? ? 'activity_grade_scale_pdf_description' : 'scho_grade_scale_pdf_description'
            scales.push build_grade_scale(description,reportable.grade_set) 
          end
          return scales.compact
        end
        
        if scholastic_grade_scale_enabled?
          scales.push build_grade_scale('scho_grade_scale_pdf_description',scholastic_grade_set)
        end
        
        if co_scholastic_grade_scale_enabled?
          scales.push build_grade_scale('activity_grade_scale_pdf_description',co_scholastic_grade_set) 
        end
        
        scales.compact
      end
      
      def build_grade_scale(name, grade_set)
        if grade_set.present?
          grades = grade_set.grades.sorted_marks
          grade_values = grades.map{|grade| [grade.name]}
          label_names = [I18n.t('grade')]
          unless grade_set.direct_grade?
            label_names << I18n.t('minimum_score')
            grades.each_with_index{|grade, index| grade_values[index].push grade.minimum_marks}
            if grade_set.enable_credit_points?
              label_names << I18n.t('credit_points')
              grades.each_with_index{|grade, index| grade_values[index].push grade.credit_points}
            end
          end
          if grade_set.description_enabled?
            label_names << I18n.t('description_text')
            grades.each_with_index{|grade, index| grade_values[index].push grade.description}
          end
          Models::GradeSet.new(
            :name =>  I18n.t(name, {:count => grades.count}),
            :labels => label_names,
            :scale => grade_values
          )
        end
      end
      
      private
      
      attr_accessor :reportable
      
      def grade_scale_enabled?
        settings[:enable_grade_scale] == '1'
      end
        
      def scholastic_grade_scale_enabled?
        grade_scale_enabled? and settings[:enable_scholastic_grade_scale] == '1' and settings[:scholastic_grade_scale].present?
      end
      
      def co_scholastic_grade_scale_enabled?
        grade_scale_enabled? and settings[:enable_co_scholastic_grade_scale] == '1' and settings[:co_scholastic_grade_scale].present?
      end
      
      def scholastic_grade_set
        grade_sets.to_a.find{|gs| gs.id == settings[:scholastic_grade_scale].try(:to_i)}
      end
      
      def co_scholastic_grade_set
        grade_sets.to_a.find{|gs| gs.id == settings[:co_scholastic_grade_scale].try(:to_i)}
      end
      
      def group_with_grade_set?
        is_assessment_group? and reportable.grade_set_id.present?
      end
      
      def is_activity_assessment_group?
        reportable.class.name == "ActivityAssessmentGroup"
      end  
    end
  end
end
