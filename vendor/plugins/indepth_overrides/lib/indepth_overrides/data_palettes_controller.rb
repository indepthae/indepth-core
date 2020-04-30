module IndepthOverrides
	module DataPalettesController
		def self.included(base)
			base.instance_eval do 
				alias_method_chain :show_palette_list, :indepth
			end
		end

		def show_palette_list_with_indepth
			@available_palettes = Palette.allowed_palettes.sort_by{|p| p.name}
			if current_user.general_admin?
				@available_palettes.reject!{|p | ["finance", "fees_due"].include? p.name} 
			end
			render :partial=>"palette_list", :locals=>{:available_palettes=>@available_palettes}
		end

	end
end