module IndepthOverrides
	module UserOverride
		def self.included(base)
			base.instance_eval do 
				before_create :assign_general_admin_role
				after_create :assign_admin_role
				alias_method_chain :role_name, :indepth
				alias_method_chain :role_symbols, :indepth
				alias_method_chain :create_default_menu_links, :indepth
				alias_method_chain :create_default_palettes, :indepth
			end

		end

		def assign_general_admin_role
		  self.general_admin = true if self.role =='GeneralAdmin'
	   	end

		def assign_admin_role
			if general_admin? && !admin?
				self.update_attribute(:admin, true)
			end
		end

		def role_name_with_indepth
		    return "General Admin" if self.general_admin?
		    return "Master Admin" if (self.admin? and self.general_admin == false)
		    return "#{t('student_text')}" if self.student?
		    return "#{t('employee_text')}" if self.employee?
		    return "#{t('parent')}" if self.parent?
		    return nil
		end

		def role_symbols_with_indepth
	    prv = []
	    privileges.map { |privilege| prv << privilege.name.underscore.to_sym } unless @privilge_symbols

	    @privilge_symbols ||= if general_admin?
	      [:admin] + prv
	    elsif admin?
	    	[:admin] + prv
	    elsif student?
	      [:student] + prv
	    elsif employee?
	      [:employee] + prv
	    elsif parent?
	      [:parent] + prv
	    else
	      prv
	    end
	  end

	  def create_default_menu_links_with_indepth
	    changes_to_be_checked = ['general_admin','admin','student','employee','parent']
	    check_changes = self.changed & changes_to_be_checked
	    if (self.new_record? or check_changes.present?)
	      self.menu_links = []
	      default_links = []
	      if self.admin? || self.general_admin?
	        main_links = MenuLink.find_all_by_name_and_higher_link_id(["human_resource","settings","students","calendar_text","news_text","event_creations"],nil)
	        default_links = default_links + main_links
	        main_links.each do|link|
	          sub_links = MenuLink.find_all_by_higher_link_id(link.id)
	          default_links = default_links + sub_links
	        end
	      elsif self.employee?
	        own_links = MenuLink.find_all_by_user_type("employee")
	        default_links = own_links + MenuLink.find_all_by_name(["news_text","calendar_text"])
	      else
	        own_links = MenuLink.find_all_by_name_and_user_type(["my_profile","timetable_text","academics","fees_text"],"student")
	        default_links = own_links + MenuLink.find_all_by_name(["news_text","calendar_text"])
	      end
	      self.menu_links = default_links
	    end
	  end

	  def create_default_palettes_with_indepth
        if FedenaPlugin.can_access_plugin?("fedena_data_palette")
          changes_to_be_checked = ['general_admin','admin','student','employee','parent']
          check_changes = self.changed & changes_to_be_checked
          if (self.new_record? or check_changes.present?)
            UserPalette.find_all_by_user_id(self.id).map{|p| p.destroy}
            default_palettes = []
            if self.general_admin?
            	default_palettes = Palette.find_all_by_name(["employees_on_leave","absent_students","news","events"])
            elsif self.admin?
            	default_palettes = Palette.find_all_by_name(["employees_on_leave","finance","absent_students","news","events","fees_due"])
            elsif self.employee?
              default_palettes = Palette.find_all_by_name(["employees_on_leave","leave_applications","news","events","timetable"])
            else
              default_palettes = Palette.find_all_by_name(["events","examinations","timetable","fees_due","news"])
            end
            default_palettes.each do|p|
              UserPalette.create(:user_id=>self.id,:palette_id=>p.id)
            end
          end
        end
      end
	end
	
end
