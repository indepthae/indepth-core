module Redactor::ModelHelper

  def has_redactor_field (field)
    BuilderMethods.make_methods(field, self)
  end

  module BuilderMethods
    def self.make_methods (field, klass)
      make_redactor_attributes(klass)
      make_delete_method(field, klass)
      make_update_method(klass)
      attach_callbacks(klass)
    end

    def self.make_redactor_attributes (klass)
      klass.send :attr_accessor, :redactor_to_update, :redactor_to_delete
    end

    def self.make_delete_method (field, klass)
      delete_method_body = <<-EOV
        def delete_redactors
          RedactorUpload.delete_after_create(self.#{field})
        end
      EOV
      klass.class_eval(delete_method_body, __FILE__)
    end

    def self.make_update_method (klass)
      update_method_body = <<-EOV
        def update_redactor
          RedactorUpload.update_redactors(self.redactor_to_update,self.redactor_to_delete)
        end
      EOV
      klass.class_eval(update_method_body, __FILE__)
    end

    def self.attach_callbacks (klass)
      klass.instance_eval do
        after_save :update_redactor
        before_destroy :delete_redactors
      end
    end
  end

end

ActiveRecord::Base.send :extend, Redactor::ModelHelper