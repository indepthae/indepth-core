class AdvanceFeeCategoryBatch < ActiveRecord::Base
  belongs_to :advance_fee_category
  belongs_to :batch

  # creating advance fee category batches
  def self.create_category_batches(adfc_id, params)
    params.values.each do |b|
      self.create(b.merge(:advance_fee_category_id => adfc_id))
    end
  end

end
