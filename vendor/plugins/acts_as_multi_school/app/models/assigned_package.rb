class AssignedPackage < ActiveRecord::Base

  belongs_to :assignee, :polymorphic=>true
  belongs_to :sms_package

  validates_presence_of :sms_package_id
  validates_numericality_of :sms_count, :only_integer=>true, :greater_than=>0,:allow_nil=>true

  after_update :modify_associated_packages
  before_destroy :delete_school_settings
  before_update :flush_plugin_cache, :if => Proc.new { |ap| ap.assignee_type=="School" }
  
  def flush_plugin_cache
    Configuration.uncache_it(['sms_setting',"/#{self.assignee_id}/", 'School'])
  end
  
  def validate
    valid_date_present = true
    if self.validity
      df = self.validity.to_date rescue false
      if df
        valid_date_present = true
        self.errors.add(:validity,"cannot be greater than 100 years.") if self.validity.to_date > (Date.today + 100.years)
      end
    end
    #self.errors.add(:validity,"cannot be a past date.") if self.validity.to_date < Date.today
    if self.assignee_type.present?
      self.errors.add_to_base("Assignee cannot be blank.") if self.assignee_id.nil?
    end
    if self.assignee.present?
      parent_row = nil
      greater_validity = nil
      infinite_validity = nil
      unlimited_count = nil
      if self.assignee.class.name == "ClientSchoolGroup"
        parent_row = AssignedPackage.find(:first,:conditions=>{:sms_package_id=>self.sms_package_id,:assignee_type=>nil})
        ms = self.assignee.multi_school_groups
        sc = self.assignee.schools
        if (self.validity and valid_date_present)
          greater_validity = AssignedPackage.find(:first,:conditions=>["validity > ? and sms_package_id = ? and ((assignee_id in (?) and assignee_type='SchoolGroup') or (assignee_id in (?) and assignee_type='School'))",self.validity.to_date,self.sms_package_id,ms.collect(&:id),sc.collect(&:id)],:order=>"validity desc")
          infinite_validity = AssignedPackage.find(:first,:conditions=>["validity IS NULL and sms_package_id = ? and ((assignee_id in (?) and assignee_type='SchoolGroup') or (assignee_id in (?) and assignee_type='School'))",self.sms_package_id,ms.collect(&:id),sc.collect(&:id)])
        end
        if (self.sms_count and self.sms_count_was.nil?)
          unlimited_count = AssignedPackage.find(:first,:conditions=>["sms_count IS NULL and sms_package_id = ? and ((assignee_id in (?) and assignee_type='SchoolGroup') or (assignee_id in (?) and assignee_type='School'))",self.sms_package_id,ms.collect(&:id),sc.collect(&:id)])
        end
      elsif self.assignee.class.name == "MultiSchoolGroup"
        sc = self.assignee.schools
        if (self.validity and valid_date_present)
          greater_validity = AssignedPackage.find(:first,:conditions=>["validity > ? and sms_package_id = ? and assignee_id in (?) and assignee_type='School'",self.validity.to_date,self.sms_package_id,sc.collect(&:id)],:order=>"validity desc")
          infinite_validity = AssignedPackage.find(:first,:conditions=>["validity IS NULL and sms_package_id = ? and assignee_id in (?) and assignee_type='School'",self.sms_package_id,sc.collect(&:id)])
        end
        if (self.sms_count and self.sms_count_was.nil?)
          unlimited_count = AssignedPackage.find(:first,:conditions=>["sms_count IS NULL and sms_package_id = ? and assignee_id in (?) and assignee_type='School'",self.sms_package_id,sc.collect(&:id)])
        end
        if self.assignee.parent_group.present?
          parent_row = self.assignee.parent_group.assigned_packages.first(:conditions=>{:sms_package_id=>self.sms_package_id})
        end
      else
        parent_row = self.assignee.school_group.assigned_packages.first(:conditions=>{:sms_package_id=>self.sms_package_id})
      end
      if parent_row.present?
        if parent_row.validity
          if (self.validity and valid_date_present)
            self.errors.add(:validity,"cannot be greater than package validity.") if self.validity.to_date > parent_row.validity.to_date
          else
            unless self.validity.present?
              self.errors.add(:validity,"can't be blank.")
            end 
          end
        end
        if parent_row.sms_count
          if self.sms_count
            self.errors.add(:sms_count, "cannot be greater than available SMS count.") if self.sms_count.to_i > (parent_row.sms_count.to_i - (parent_row.sms_used.to_i - self.sms_count_was.to_i))
          else
            self.errors.add(:sms_count, "can't be blank.")
          end
        end
      end
      self.errors.add_to_base("This package is already assigned.") unless (self.assignee.assigned_packages.all(:conditions=>{:sms_package_id=>self.sms_package_id}) - self.to_a).empty?
      self.errors.add_to_base("Package with validity #{greater_validity.validity} already assigned. Validity cannot be less than that.") if greater_validity.present?
      self.errors.add_to_base("Package with lifetime validity already assigned.") if infinite_validity.present?
      self.errors.add_to_base("Package with unlimited SMS count already assigned.") if unlimited_count.present?
    end
    if self.sms_count
      self.errors.add_to_base("#{self.sms_used.to_i} SMS have already been used. Message Limit cannot be less than that.") if self.sms_count.to_i < self.sms_used.to_i

    end
  end

  def delete_school_settings
    if self.assignee.present?
      if self.assignee_type=="School" and self.is_using==true
        self.assignee.sms_credential.destroy if self.assignee.sms_credential.present?
      end
    end
  end

  def modify_associated_packages
    if self.assignee.nil?
      if self.sendername_changed?
        assigned_clients = AssignedPackage.find(:all,:conditions=>{:assignee_type=>"SchoolGroup",:assignee_id=>ClientSchoolGroup.active.collect(&:id),:sms_package_id=>self.sms_package_id,:enable_sendername_modification=>false})
        assigned_clients.map{|a| a.update_attributes(:sendername=>self.sendername)}
      end
      if (self.enable_sendername_modification_changed? and self.enable_sendername_modification==false)
        enabled_clients = AssignedPackage.find(:all,:conditions=>{:assignee_type=>"SchoolGroup",:assignee_id=>ClientSchoolGroup.active.collect(&:id),:sms_package_id=>self.sms_package_id,:enable_sendername_modification=>true})
        enabled_clients.map{|e| e.update_attributes(:sendername=>self.sendername,:enable_sendername_modification=>false)}
      end
    elsif self.assignee_type == "SchoolGroup"
      assigned_group = self.assignee
      if self.sendername_changed?
        if assigned_group.class.name=="ClientSchoolGroup"
          assigned_ms = AssignedPackage.find(:all,:conditions=>{:assignee_type=>"SchoolGroup",:assignee_id=>assigned_group.multi_school_groups.collect(&:id),:sms_package_id=>self.sms_package_id,:enable_sendername_modification=>false})
          assigned_ms.map{|a| a.update_attributes(:sendername=>self.sendername)}
        end
        if self.enable_sendername_modification == false
          assigned_schools = AssignedPackage.find(:all,:conditions=>{:assignee_type=>"School",:assignee_id=>assigned_group.schools.collect(&:id),:sms_package_id=>self.sms_package_id})
          assigned_schools.map{|a| a.update_attributes(:sendername=>self.sendername)}
        end
      end
      if (self.enable_sendername_modification_changed? and self.enable_sendername_modification==false)
        if assigned_group.class.name=="ClientSchoolGroup"
          enabled_ms = AssignedPackage.find(:all,:conditions=>{:assignee_type=>"SchoolGroup",:assignee_id=>assigned_group.multi_school_groups.collect(&:id),:sms_package_id=>self.sms_package_id,:enable_sendername_modification=>true})
          enabled_ms.map{|e| e.update_attributes(:sendername=>self.sendername,:enable_sendername_modification=>false)}
        end
        enabled_schools = AssignedPackage.find(:all,:conditions=>{:assignee_type=>"School",:assignee_id=>assigned_group.schools.collect(&:id),:sms_package_id=>self.sms_package_id})
        enabled_schools.map{|e| e.update_attributes(:sendername=>self.sendername)}
      end
    elsif self.assignee_type == "School"
      if self.is_using
        if self.is_using_changed? or self.sendername_changed?
          setting = self.assignee.sms_credential
          setting = self.assignee.build_sms_credential if setting.nil?
          setting.settings = self.sms_package.settings
          setting.settings[:sms_settings][:sendername] = self.sendername
          setting.save
          if self.is_using_changed?
            used_packages = self.assignee.assigned_packages.all(:conditions=>{:is_using=>true}) - self.to_a
            used_packages.each do|u|
              u.update_attributes(:is_using=>false)
            end
          end
        end
      else
        if self.is_using_changed?
          used_packages = self.assignee.assigned_packages.all(:conditions=>{:is_using=>true}) - self.to_a
          if used_packages.empty?
            self.assignee.sms_credential.destroy if self.assignee.sms_credential.present?
          end
        end
      end
    end
  end

end
