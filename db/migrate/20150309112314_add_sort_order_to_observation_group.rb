class AddSortOrderToObservationGroup < ActiveRecord::Migration
  def self.up
    add_column :observation_groups,    :sort_order,   :integer
  end

  def self.down
    remove_column :observation_groups,    :sort_order,   :integer
  end
end
