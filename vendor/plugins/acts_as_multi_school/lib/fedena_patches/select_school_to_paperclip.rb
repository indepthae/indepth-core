module FedenaPatches
  module SelectSchoolToPaperclip
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        class << self
          alias_method_chain :paperclip_attachment_return, :ms
        end
      end
    end

    module ClassMethods
      def paperclip_attachment_return_with_ms(env)
        request_host=env["HTTP_HOST"]
        if Regexp.new('^resource-\d+-m.'+"#{MultiSchool.default_domain.gsub(/\./,'\.')}$").match(request_host)
          @linkable = School.find_by_id(request_host[/resource\-(.*?)-m/,1])
        else
          domain = SchoolDomain.find_by_domain(request_host)
          @linkable = domain.linkable unless domain.blank?   
        end
        if @linkable and @linkable.class.name == "School"
          MultiSchool.current_school= @linkable
          paperclip_attachment_return_without_ms(env)
        else
          [404, {"Content-Type" => "text/html"}, ["Not Found"]]
        end
      end
    end
  end
end