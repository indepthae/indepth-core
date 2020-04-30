class ActiveRecord::Base
  include Notifier
  extend Notifier
  
  def copy_with_associations(assoc_hash = {})
    
    # ################################# Example ###########################
    # assoc_hash = {
    #     :associations => ['assessment_groups'],
    #     :assessment_groups => {
    #         :associations => ['derived_assessment_group_setting'],
    #         :derived_assessment_group_setting => {}
    #       }
    #     }
    # #####################################################################
    
    reflection_array = []
    exclude_array = []
    polymorphic_relations = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    self.class.reflections.each do |assoc_name, reflection|
      if reflection.is_a?(::ActiveRecord::Reflection::ThroughReflection)
        exclude_array << reflection.options[:through].to_s
      end
      polymorphic_relations[assoc_name] = reflection.options[:as] if reflection.options[:as].present? and [:has_many, :has_one].include? reflection.macro
      puts reflection.inspect
      puts "----------------------------------++++++++++#{reflection.options[:polymorphic]}"
      reflection_array << assoc_name.to_s if [:has_many, :has_one].include? reflection.macro and  !reflection.is_a?(::ActiveRecord::Reflection::ThroughReflection)
    end
    reflection_array = (assoc_hash[:associations] & reflection_array || []) - exclude_array
    puts reflection_array.inspect
    copy = self.clone
    
    reflection_array.each do |reflection|
      if reflection.pluralize != reflection && reflection.singularize == reflection
        child = self.send(reflection)
        copy.send("build_#{reflection}",child.send(:copy_with_associations, assoc_hash[reflection.to_sym]).try(:attributes)) if child.present? #Only one level of cloning for has_one
      else
        self.send(reflection).each do |child|
          child_copy = child.send(:copy_with_associations,assoc_hash[reflection.to_sym] )
          if polymorphic_relations[reflection.to_sym].present?
            child_copy.send("#{polymorphic_relations[reflection.to_sym].to_s}_id=", nil)
            child_copy.send("#{polymorphic_relations[reflection.to_sym].to_s}_type=", nil)
          else
            child_copy.send("#{self.class.name.underscore}_id=", nil)
          end
          copy.send(reflection) << child_copy
        end
      end
    end
    
    return copy
  end
  
end

class ActionController::Base
  include Notifier
end
class ActionView::Base
  include Notifier
end