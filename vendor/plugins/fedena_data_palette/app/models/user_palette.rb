class UserPalette < ActiveRecord::Base
  belongs_to :user
  belongs_to :palette

  after_create :assign_position
  before_destroy :rearrange_positions

  validates_presence_of :user_id, :palette_id
  #validates_uniqueness_of :position, :scope=>:user_id, :allow_nil=>true

  def rearrange_positions
    lower_palettes = UserPalette.find(:all, :conditions=>["user_id = ? AND column_number = ? AND position > ?",self.user_id,self.column_number,self.position])
    lower_palettes.each do|palette|
      palette.update_attributes(:position=>(palette.position-1))
    end
  end

  def assign_position
    all_palettes = UserPalette.find_all_by_user_id(self.user_id)
    first_column = all_palettes.select{|c| c.column_number==1}.count
    second_column = all_palettes.select{|c| c.column_number==2}.count
    third_column = all_palettes.select{|c| c.column_number==3}.count
    count_array = [[first_column,1],[second_column,2],[third_column,3]].sort
    assigned_column = count_array[0][1]
    assigned_position = (count_array[0][0] + 1)
    self.update_attributes(:column_number=>assigned_column,:position=>assigned_position)
  end

end

