class AddIsCoCurricularToIcseWeightage < ActiveRecord::Migration
  def self.up
    add_column    :icse_weightages, :is_co_curricular, :boolean,:default=>false
  end

  def self.down
    remove_column    :icse_weightages, :is_co_curricular
  end
end
