require 'active_record'

class ActiveRecord::Base
  module DeepCloneable
    # Deep dups an ActiveRecord model. See README.rdoc
    def deep_clone(*args, &block)
      options = args[0] || {}

      dictionary = options[:dictionary]
      dictionary ||= {} if options.delete(:use_dictionary)

      kopy = if dictionary
               find_in_dictionary_or_dup(dictionary)
             else
               clone
             end

      yield(self, kopy) if block

      deep_exceptions = {}
      if options[:except]
        exceptions = options[:except].nil? ? [] : [options[:except]].flatten
        exceptions.each do |attribute|
          dup_default_attribute_value_to(kopy, attribute, self) unless attribute.is_a?(Hash)
        end
        deep_exceptions = exceptions.select { |e| e.is_a?(Hash) }.inject({}) { |m, h| m.merge(h) }
      end

      deep_onlinesses = {}
      if options[:only]
        onlinesses = options[:only].nil? ? [] : [options[:only]].flatten
        object_attrs = kopy.attributes.keys.collect(&:to_sym)
        exceptions = object_attrs - onlinesses
        exceptions.each do |attribute|
          dup_default_attribute_value_to(kopy, attribute, self) unless attribute.is_a?(Hash)
        end
        deep_onlinesses = onlinesses.select { |e| e.is_a?(Hash) }.inject({}) { |m, h| m.merge(h) }
      end

      if options[:include]
        normalized_includes_list(options[:include]).each do |association, conditions_or_deep_associations|
          conditions = {}

          if association.is_a? Hash
            conditions_or_deep_associations = association[association.keys.first]
            association = association.keys.first
          end

          if conditions_or_deep_associations.is_a?(Hash)
            conditions_or_deep_associations = conditions_or_deep_associations.dup
            conditions[:if]     = conditions_or_deep_associations.delete(:if)     if conditions_or_deep_associations[:if]
            conditions[:unless] = conditions_or_deep_associations.delete(:unless) if conditions_or_deep_associations[:unless]
          elsif conditions_or_deep_associations.is_a?(Array)
            conditions_or_deep_associations = conditions_or_deep_associations.dup
            conditions_or_deep_associations.delete_if { |entry| conditions.merge!(entry) if entry.is_a?(Hash) && (entry.key?(:if) || entry.key?(:unless)) }
          end

          dup_options = {}
          dup_options[:include] = conditions_or_deep_associations if conditions_or_deep_associations.present?
          dup_options[:except] = deep_exceptions[association] if deep_exceptions[association]
          dup_options[:only] = deep_onlinesses[association] if deep_onlinesses[association]
          dup_options[:dictionary] = dictionary if dictionary
          dup_options[:skip_missing_associations] = options[:skip_missing_associations] if options[:skip_missing_associations]

          if (association_reflection = self.class.reflect_on_association(association))
            if options[:validate] == false
              kopy.instance_eval do
                # Force :validate => false on all saves.
                def perform_validations(options = {})
                  options[:validate] = false
                  super(options)
                end
              end
            end

            association_type = association_reflection.macro
            association_type = "#{association_type}_through" if association_reflection.is_a?(ActiveRecord::Reflection::ThroughReflection)

            duped_object = send(
              "dup_#{association_type}_association",
              { :reflection => association_reflection, :association => association, :copy => kopy, :conditions => conditions, :dup_options => dup_options },
              &block
            )

            kopy.send("#{association}=", duped_object)
          elsif !options[:skip_missing_associations]
            raise AssociationNotFoundException, "#{self.class}##{association}"
          end
        end
      end

      kopy
    end

    protected

    def find_in_dictionary_or_dup(dictionary, dup_on_miss = true)
      tableized_class = self.class.name.tableize.to_sym
      dictionary[tableized_class] ||= {}
      dict_val = dictionary[tableized_class][self]
      dict_val.nil? && dup_on_miss ? dictionary[tableized_class][self] = dup : dict_val
    end

    private

    def dup_belongs_to_association(options, &block)
      object = deep_cloneable_object_for(options[:association], options[:conditions])
      object && object.deep_clone(options[:dup_options], &block)
    end

    def dup_has_one_association(options, &block)
      dup_belongs_to_association options, &block
    end

    def dup_has_many_association(options, &block)
      foreign_key = options[:reflection].primary_key_name.to_s
      reverse_association = find_reverse_association(options[:reflection], foreign_key, :belongs_to)
      objects = deep_cloneable_objects_for(options[:association], options[:conditions])

      objects.map do |object|
        object = object.deep_clone(options[:dup_options], &block)
        object.send("#{foreign_key}=", nil)
        object.send("#{reverse_association.name}=", options[:copy]) if reverse_association
        object
      end
    end

    def dup_has_one_through_association(options, &block)
      foreign_key = options[:reflection].through_reflection.primary_key_name.to_s
      reverse_association = find_reverse_association(options[:reflection], foreign_key, :has_one, :association_foreign_key)

      object = deep_cloneable_object_for(options[:association], options[:conditions])
      object && process_joined_object_for_deep_clone(object, options.merge(:reverse_association => reverse_association), &block)
    end

    def dup_has_many_through_association(options, &block)
      foreign_key = options[:reflection].through_reflection.primary_key_name.to_s
      reverse_association = find_reverse_association(options[:reflection], foreign_key, :has_many, :association_foreign_key)

      objects = deep_cloneable_objects_for(options[:association], options[:conditions])
      objects.map { |object| process_joined_object_for_deep_clone(object, options.merge(:reverse_association => reverse_association), &block) }
    end

    def dup_has_and_belongs_to_many_association(options, &block)
      foreign_key = options[:reflection].primary_key_name.to_s
      reverse_association = find_reverse_association(options[:reflection], foreign_key, :has_and_belongs_to_many, :association_foreign_key)

      objects = deep_cloneable_objects_for(options[:association], options[:conditions])
      objects.map { |object| process_joined_object_for_deep_clone(object, options.merge(:reverse_association => reverse_association), &block) }
    end

    def find_reverse_association(source_reflection, primary_key_name, macro, matcher = :primary_key_name)
#      if source_reflection.inverse_of.present?
#        source_reflection.inverse_of
#      else
        source_reflection.klass.reflect_on_all_associations.detect do |reflection|
          reflection != source_reflection && (macro.nil? || reflection.macro == macro) && (reflection.send(matcher).to_s == primary_key_name)
#        end
      end
    end

    def deep_cloneable_object_for(single_association, conditions)
      object = send(single_association)
      evaluate_conditions(object, conditions) && object
    end

    def deep_cloneable_objects_for(many_association, conditions)
      send(many_association).select { |object| evaluate_conditions(object, conditions) }
    end

    def process_joined_object_for_deep_clone(object, options, &block)
      if (dictionary = options[:dup_options][:dictionary]) && object.find_in_dictionary_or_dup(dictionary, false)
        object = object.deep_clone(options[:dup_options], &block)
      elsif options[:reverse_association]
        object.send(options[:reverse_association].name).target << options[:copy]
      end
      object
    end

    def evaluate_conditions(object, conditions)
      conditions.none? || (conditions[:if] && conditions[:if].call(object)) || (conditions[:unless] && !conditions[:unless].call(object))
    end

    def dup_default_attribute_value_to(kopy, attribute, origin)
      kopy[attribute] = origin.class.column_defaults.dup[attribute.to_s]
    end

    def normalized_includes_list(includes)
      list = []
      Array(includes).each do |item|
        if item.is_a?(Hash) && item.size > 1
          item.each { |key, value| list << { key => value } }
        else
          list << item
        end
      end

      list
    end

    class AssociationNotFoundException < StandardError; end

    ActiveRecord::Base.class_eval { protected :initialize_dup } if ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR == 1
  end

  include DeepCloneable
end