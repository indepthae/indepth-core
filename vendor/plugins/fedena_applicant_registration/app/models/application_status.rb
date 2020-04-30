class ApplicationStatus < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name, :scope=>"school_id", :case_sensitive=>false
  
  DEFAULT_STATUSES = [{:name=>"pending",:description=>"The application is being processed",:notification_enabled=>false,:is_active=>true,:is_default=>true},
    {:name=>"alloted",:description=>"The applicant has been allotted to a batch",:notification_enabled=>false,:is_active=>true,:is_default=>true},
    {:name=>"discarded",:description=>"The application has been discarded",:notification_enabled=>false,:is_active=>true,:is_default=>true}
  ]
  
  def validate
    unless self.new_record?
      if self.is_default==true
        if self.changed and self.changed.include?("name")
          self.errors.add_to_base("Can't modify name of default status.")
        end
        if self.changed and self.changed.include?("is_active") and self.is_active==false
          self.errors.add_to_base("Can't inactivate a default status.")
        end
      end
    end
    if ((self.new_record? and self.is_active==true) or (self.changed and self.changed.include?("is_active") and self.is_active == true))
      self.errors.add_to_base("Can't keep more than 10 active status at a time.") unless (ApplicationStatus.count(:all,:conditions=>{:is_active=>true}) < 10)
    end
  end
  
  def can_be_edited?
    return true
  end
  
  def can_be_deleted?
    if (self.is_default == true or Applicant.exists?(:status=>self.id.to_s))
      return false
    else
      return true
    end 
  end

  def self.create_defaults_and_return
    ApplicationStatus::DEFAULT_STATUSES.each do|v|
      ApplicationStatus.create(v)
    end
    return ApplicationStatus.all
  end
end
