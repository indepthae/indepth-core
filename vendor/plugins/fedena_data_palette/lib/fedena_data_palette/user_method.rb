# To change this template, choose Tools | Templates
# and open the template in the editor.

module FedenaDataPalette
  module UserMethod
    def self.included(base)
      base.send :after_save, :create_default_palettes

      base.class_eval do
        def own_palettes
          my_palettes = self.palettes.all(:include=>[:palette_queries])
          permitted_palettes = Palette.compatible_palettes(my_palettes,self.role_symbols)
          unpermitted_palettes = my_palettes - permitted_palettes
          unpermitted_palettes.map{|p| self.delete_unauthorized_palette(p.id)}
          return self.user_palettes.all(:include=>[:palette])
        end


        def create_default_palettes
          if FedenaPlugin.can_access_plugin?("fedena_data_palette")
            changes_to_be_checked = ['admin','student','employee','parent']
            check_changes = self.changed & changes_to_be_checked
            if (self.new_record? or check_changes.present?)
              UserPalette.find_all_by_user_id(self.id).map{|p| p.destroy}
              default_palettes = []
              if self.admin?
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
        
        def delete_unauthorized_palette(palette_id)
          palette = UserPalette.find_by_palette_id_and_user_id(palette_id,self.id)
          palette.destroy if palette.present?
        end

      end
    end

  end

  module DashboardOverride
    def self.included(base)
      base.send :before_filter, :redirect_to_palettes, :only=>[:dashboard]
    end

    def redirect_to_palettes
      if current_user.parent?
        session[:student_id]=params[:id].present?? params[:id] : current_user.guardian_entry.current_ward.id
        Fedena.present_student_id=session[:student_id]
      end
      redirect_to :controller=>"data_palettes", :action=>"index" if (current_user.id!=0 and can_access_request?(:index,:data_palettes))
      return
    end
  end
end
