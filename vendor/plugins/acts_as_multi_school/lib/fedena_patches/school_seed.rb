module FedenaPatches
  module SchoolSeed
    def self.included(base)
      base.extend ClassMethods
      #      base.extend MultiSchool::Read
      #      base.include MultiSchool::Write

      base.class_eval do
        class << self
          alias_method_chain :update_school,:school_id
        end
      end
    end

    module ClassMethods
      def update_school_with_school_id
        School.active.each do |school|
          MultiSchool.current_school=school
          update_school_run(school.id)
        end
      end
    end
  end
end