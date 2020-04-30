class TaxSlab < ActiveRecord::Base
#  belongs_to :tax_group
  
  #  has_many :finance_fee_collections, :through => :taxable_slabs, :source => :taxable, 
  #    :source_type => 'FinanceFeeCollection'
  has_many :tax_assignments, :dependent => :destroy
  has_many :finance_fee_particulars, :through => :tax_assignments, :source => :taxable, 
    :source_type => 'FinanceFeeParticular'

  has_many :collectible_tax_slabs
  has_many :collection_fee_particulars, :through => :collectible_tax_slabs, :source => :collectible_entity, 
    :source_type => 'FinanceFeeParticular'
  
  has_many :finance_fee_collections, :through => :collectible_tax_slabs, :source => :collection,
    :source_type => "FinanceFeeCollection"
  
  has_many :tax_collections, :dependent => :destroy, :foreign_key => 'slab_id'
  
  validates_uniqueness_of :name
  validates_presence_of :name, :rate  
  #  validates_presence_of :tax_group_id

  validates_numericality_of :rate, :greater_than_equal_to => 0
  default_scope :order => "name asc"
    
  
  def has_assignments?
    if tax_assignments.present? or collectible_tax_slabs.present?
      errors.add_to_base(t('tax_slab_is_assigned_to_particular_or_collection_with_tax_slab_exists'))
      return true
    else
      return false
    end
  end
end