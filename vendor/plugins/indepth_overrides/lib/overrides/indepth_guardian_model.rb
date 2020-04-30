module IndepthOverrides
  module IndepthGuardianModel
  	def self.included (base)
  		base.instance_eval do
	  		alias_method_chain :update_immediate_contact, :tmpl
	  		alias_method_chain :create_guardian_user, :tmpl
        #        after_save :update_familyid
	  	end
      base.class_eval do
        def self.shift_user(student)
          current_student=Student.find(student.id)
          current_guardian =  student.immediate_contact
          return if current_guardian.nil?    
          siblings = Student.find(:all,:conditions=>"sibling_id=#{current_guardian.ward_id}")
          if current_guardian.user.present?      
            if siblings.present?
              stu_with_p_username = "p"+siblings.first.admission_no.to_s
            else
              stu_with_p_username = "p"+student.admission_no.to_s
            end
            replacing_u_name = current_guardian.user.username
            correct_guardian = User.find_by_username(stu_with_p_username)
            replacing_user = current_guardian.user
            correct_guardian.update_attributes(:username =>"xxx") if correct_guardian.present?
            updated_user = replacing_user
            updated_user.reload
            updated_user.update_attributes(:username=>stu_with_p_username,:password=> "#{student.familyid}123")
            replacing_user.reload            
            correct_guardian.update_attributes(:username =>replacing_u_name,:password=> "#{student.familyid}123") if correct_guardian.present?                  
          end
          Guardian.find(:all,:conditions=>"ward_id=#{current_student.sibling_id}").each do |g|
            #student.guardians.each do |g|

            unless (current_student.all_siblings).collect(&:immediate_contact_id).include?(g.id)
              parent_user = g.user
              parent_user.soft_delete if parent_user.present? and (parent_user.is_deleted==false)and ((current_guardian.present? ) and current_guardian!=g)
              #parent_user.soft_delete if parent_user.present? and (parent_user.is_deleted==false) and ((current_guardian.present? and current_guardian.user.present?) and current_guardian.user!=parent_user)

            end
          end

          if current_guardian.present?
            if current_guardian.user.present?
                current_guardian.user.update_attribute(:is_deleted,false) if current_guardian.user.is_deleted
              else
                current_guardian.create_guardian_user(student)
              end
            end
          end
      end     
  	end
    
    #    def update_familyid
    #      if self.current_ward.familyid != self.familyid
    #        immediate_contacts = Student.find_all_by_immediate_contact_id(id)
    #        immediate_contacts.each do |i_c| 
    #          i_c.familyid = familyid
    #          i_c.save(:update_without_callbacks)
    #        end        
    #      end        
    #    end
    def create_guardian_user_with_tmpl(student)      
      user = User.new do |u|
        u.first_name = self.first_name
        u.last_name = self.last_name
        u_name="p"+student.admission_no.to_s
        temp_u_name = u_name
        begin
          user_record=User.find_by_username(u_name)
          if user_record.present?
            u_name=u_name.next
          end
        end while user_record.present?
        old_user_record = User.find_by_username(temp_u_name)
        unless old_user_record.nil?          
          old_user_record.update_attributes(:username=> u_name,:password=> "#{student.familyid}123")
        end        
        u.username = temp_u_name
        u.password = "#{student.familyid}123"
        u.role = 'Parent'
        u.email = ( email != '' or User.active.find_by_email(self.email) ) ? self.email.to_s : ""        
      end       
      if user.save        
        unless self.update_attributes(:user_id => user.id)
          raise ActiveRecord::Rollback
        end      
      end
    end
    
    def update_immediate_contact_with_tmpl
      student = Student.find(ward_id)
      create_guardian_user(student) unless self.user.present?
      # fix guardian's familyid imported from custom import or if attempted to change
      unless self.familyid == student.familyid
        self.familyid = student.familyid
        self.save(:update_without_callbacks)        
      end
      
      #fix familyid of all sibling & sibling guardians to student's family who is getting this guardian record
      if set_immediate_contact.present?
        siblings = Student.find_all_by_admission_no_and_sibling_id(
          set_immediate_contact.split('|'), ward_id, :include => :guardians)
        # set immediate contact 
        siblings.each{ |sibling| sibling.update_attributes(:immediate_contact_id => id) }
        # fixing familyid of all siblings as per csv
        sibling_ids = siblings.map {|x| x.id if x.familyid != student.familyid }.compact
        guardians = siblings.map {|x| x.guardians.select {|g| g if g.familyid != student.familyid} }.flatten.compact
        Student.update_all("familyid = #{student.familyid}", {:id => sibling_ids}) if sibling_ids.present?
        if guardians.present? and student.familyid.present?
          Guardian.update_all("familyid = #{student.familyid}", {:id => guardians.map(&:id)})           
          guardians.each do |g|
            u = g.user
            next unless u.present?
            u.password = "#{student.familyid}123"
            u.save
          end
        end
      end
    end
  end
end
