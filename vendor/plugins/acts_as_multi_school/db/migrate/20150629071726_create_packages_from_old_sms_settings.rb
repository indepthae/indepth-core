class CreatePackagesFromOldSmsSettings < ActiveRecord::Migration
  def self.up
    unless SmsCredential.all.empty?
      if SmsPackage.all.empty?
        School.all(:joins=>"inner join additional_settings on additional_settings.owner_id=schools.id",:conditions=>["additional_settings.owner_type='School' and additional_settings.type='SmsCredential'"],:include=>[:sms_credential,:school_group]).each do|s|
          unless s.school_group.nil?
            cp = SmsPackage.create(:name=>"#{s.code} sms package",:service_provider=>"N/A",:message_limit=>nil,:validity=>nil,:settings=>s.sms_credential.settings,:enable_sendername_modification=>false,:character_limit=>nil)
            AssignedPackage.create(:sms_package_id=>cp.id,:assignee=>s.school_group,:is_using=>false,:enable_sendername_modification=>false,:sendername=>cp.settings[:sms_settings][:sendername],:is_owner=>true,:sms_count=>nil,:sms_used=>0,:validity=>nil)
            AssignedPackage.create(:sms_package_id=>cp.id,:assignee=>s,:is_using=>(s.inherit_sms_settings==false),:enable_sendername_modification=>false,:sendername=>cp.settings[:sms_settings][:sendername],:is_owner=>false,:sms_count=>nil,:sms_used=>0,:validity=>nil) unless s.is_deleted
          end
        end
        MultiSchoolGroup.all(:joins=>"inner join additional_settings on additional_settings.owner_id=school_groups.id",:conditions=>["additional_settings.owner_type='SchoolGroup' and additional_settings.type='SmsCredential'"],:include=>:sms_credential).each do|m|
          mp = SmsPackage.create(:name=>"SMS Package",:service_provider=>"N/A",:message_limit=>nil,:validity=>nil,:settings=>m.sms_credential.settings,:enable_sendername_modification=>false,:character_limit=>nil)
          AssignedPackage.create(:sms_package_id=>mp.id,:assignee=>m,:is_using=>false,:enable_sendername_modification=>false,:sendername=>mp.settings[:sms_settings][:sendername],:is_owner=>true,:sms_count=>nil,:sms_used=>0,:validity=>nil)
          ms = m.schools.active.all(:conditions=>{:inherit_sms_settings=>true})
          ms.each do|s|
            AssignedPackage.create(:sms_package_id=>mp.id,:assignee=>s,:is_using=>true,:enable_sendername_modification=>false,:sendername=>mp.settings[:sms_settings][:sendername],:is_owner=>false,:sms_count=>nil,:sms_used=>0,:validity=>nil)
            SmsCredential.create(:owner=>s,:settings=>mp.settings)
          end
          m.sms_credential.destroy
        end
        client_present = ClientSchoolGroup rescue false
        unless client_present==false
          ClientSchoolGroup.all(:joins=>"inner join additional_settings on additional_settings.owner_id=school_groups.id",:conditions=>["additional_settings.owner_type='SchoolGroup' and additional_settings.type='SmsCredential'"],:include=>:sms_credential).each do|c|
            if c.sms_credential
              cp = SmsPackage.create(:name=>"SMS Package",:service_provider=>"N/A",:message_limit=>nil,:validity=>nil,:settings=>c.sms_credential.settings,:enable_sendername_modification=>false,:character_limit=>nil)
              AssignedPackage.create(:sms_package_id=>cp.id,:assignee=>c,:is_using=>false,:enable_sendername_modification=>false,:sendername=>cp.settings[:sms_settings][:sendername],:is_owner=>true,:sms_count=>nil,:sms_used=>0,:validity=>nil)
              ms = c.multi_school_groups.all(:conditions=>{:inherit_sms_settings=>true})
              ms.each do|m|
                AssignedPackage.create(:sms_package_id=>cp.id,:assignee=>m,:is_using=>false,:enable_sendername_modification=>false,:sendername=>cp.settings[:sms_settings][:sendername],:is_owner=>false,:sms_count=>nil,:sms_used=>0,:validity=>nil)
                sc = m.schools.active.all(:conditions=>{:inherit_sms_settings=>true})
                sc.each do|s|
                  AssignedPackage.create(:sms_package_id=>cp.id,:assignee=>s,:is_using=>true,:enable_sendername_modification=>false,:sendername=>cp.settings[:sms_settings][:sendername],:is_owner=>false,:sms_count=>nil,:sms_used=>0,:validity=>nil)
                  SmsCredential.create(:owner=>s,:settings=>cp.settings)
                end
              end
              cs = c.schools.active.all(:conditions=>{:inherit_sms_settings=>true})
              cs.each do|s|
                AssignedPackage.create(:sms_package_id=>cp.id,:assignee=>s,:is_using=>true,:enable_sendername_modification=>false,:sendername=>cp.settings[:sms_settings][:sendername],:is_owner=>false,:sms_count=>nil,:sms_used=>0,:validity=>nil)
                SmsCredential.create(:owner=>s,:settings=>cp.settings)
              end
              c.sms_credential.destroy
            end
          end
        end
      end
    end
  end

  def self.down
  end
end
