module FedenaPatches
  module SmsLogPatch
    def self.included(base)
      base.instance_eval do
        def get_sms_messages(page = 1)
          @school = MultiSchool.current_school
          SmsMessage.paginate(:conditions=>{:school_id=>@school.id}, :order=>"id DESC", :page => page, :per_page => 30)
        end
      end
    end
  end
end