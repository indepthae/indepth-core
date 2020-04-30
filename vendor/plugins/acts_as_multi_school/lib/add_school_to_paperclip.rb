module AddSchoolToPaperclip

  def self.included(base)
    base.class_eval do
      begin
        self.attachment_definitions.each do |k,v|
          path_arr = v[:path].split("/")
          path_arr[1] = ":school_id/"+path_arr[1] unless v[:path].include?(":school_id")
          path = path_arr.join("/")
          v[:path] = path
        end
#        Paperclip.interpolates :school_id do |school, style|
#          custom_id_partition school.instance.school.id
#        end
      rescue
        # if a model doesn't have attachment, it will be rescued.
      end
    end
  end
  
end
