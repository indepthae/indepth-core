class DataPalettesController < ApplicationController
  before_filter :login_required
  before_filter :default_time_zone_present_time
  filter_access_to :all

  def index
    @user_palettes = current_user.own_palettes
    @today = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    # @cur_date = Date.today
    @cur_date = @today
  end

  def update_palette
    current_palette = Palette.find_by_name(params[:palette][:palette_name])
    @cur_date = params[:palette][:cur_date].to_date
    render :partial=>"palette_subcontent", :locals=>{:palette=>current_palette, :cur_date=>@cur_date, :off=>0, :lim=>4}
  end

  def toggle_minimize
    palette_id = params[:palette][:id].to_i
    user_palette = UserPalette.find_by_user_id_and_palette_id(current_user.id,palette_id)
    unless user_palette.nil?
      if user_palette.is_minimized == false
        user_palette.is_minimized = true
      else
        user_palette.is_minimized = false
      end
      user_palette.save
    end
    render :text=>"#{palette_id}"
  end

  def remove_palette
    palette_id = params[:palette][:id].to_i
    user_palette = UserPalette.find_by_user_id_and_palette_id(current_user.id,palette_id)
    user_palette.destroy unless user_palette.nil?
    render :text=>"removed"
  end

  def refresh_palette
    palette = Palette.find(params[:palette][:id].to_i)
    @today = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    # @cur_date = Date.today
    @cur_date = @today
    render :partial=>"palette_content", :locals=>{:palette=>palette, :cur_date=>@cur_date, :off=>0, :lim=>4}
  end

  def show_palette_list
    @available_palettes = Palette.allowed_palettes.sort_by{|p| p.name}
    render :partial=>"palette_list", :locals=>{:available_palettes=>@available_palettes}
  end

  def modify_user_palettes
    selected_palettes = []
    if params[:palette] and params[:palette][:selected_palettes]
      selected_palettes = params[:palette][:selected_palettes]
    end
    prev_palettes = current_user.palettes.map{|p| p.id.to_s}
    removed_palettes = prev_palettes - selected_palettes
    added_palettes = selected_palettes - prev_palettes
    unless removed_palettes.empty?
      UserPalette.find_all_by_user_id_and_palette_id(current_user.id,removed_palettes).map{|u| u.destroy}
    end
    unless added_palettes.empty?
      added_palettes.each do|palette|
        UserPalette.create(:user_id=>current_user.id,:palette_id=>palette.to_i)
      end
    end
    @today = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    #redirect_to :controller=>"data_palettes", :action=>"index"
    render :partial=>"palettes_main", :locals=>{:user_palettes=>current_user.own_palettes, :cur_date=>@today}
  end

  def sort_palettes
    palette = Palette.find(params[:palette][:id].to_i)
    current_palette = UserPalette.find_by_user_id_and_palette_id(current_user.id,palette.id)
    unless current_palette.nil?
      previous_column = current_palette.column_number
      previous_position = current_palette.position
      new_column = params[:palette][:column_number].to_i
      new_position = params[:palette][:position].to_i
      if previous_column == new_column
        if previous_position > new_position
          intermediate_palettes = UserPalette.find_all_by_user_id_and_column_number_and_position(current_user.id,new_column,(new_position..(previous_position-1)).to_a)
          intermediate_palettes.each do|palette|
            palette.update_attributes(:position=>(palette.position+1))
          end
        else
          intermediate_palettes = UserPalette.find_all_by_user_id_and_column_number_and_position(current_user.id,new_column,((previous_position+1)..new_position).to_a)
          intermediate_palettes.each do|palette|
            palette.update_attributes(:position=>(palette.position-1))
          end
        end
      else
        old_column_palettes = UserPalette.find(:all, :conditions=>["user_id = ? AND column_number = ? AND position > ?",current_user.id,previous_column,previous_position])
        new_column_palettes = UserPalette.find(:all, :conditions=>["user_id = ? AND column_number = ? AND position >= ?",current_user.id,new_column,new_position])
        old_column_palettes.each do|palette|
          palette.update_attributes(:position=>(palette.position-1))
        end
        new_column_palettes.each do|palette|
          palette.update_attributes(:position=>(palette.position+1))
        end
      end
      current_palette.update_attributes(:column_number=>new_column, :position=>new_position)
    end
    render :text=>""
  end

  def view_more
    current_palette = Palette.find_by_name(params[:palette][:palette_name])
    offset = params[:palette][:offset].to_i
    cur_date = params[:palette][:cur_date].to_date
    render :partial=>"palette_subcontent", :locals=>{:palette=>current_palette, :cur_date=>cur_date, :off=>offset, :lim=>4}
  end

end
