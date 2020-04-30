class InstantFeeParticular < ActiveRecord::Base
  belongs_to :instant_fee_category
  belongs_to :master_fee_particular
  # tax associations
  has_many :tax_assignments, :as => :taxable
  has_many :tax_slabs, :through => :tax_assignments, :class_name => "TaxSlab"

  has_many :collectible_tax_slabs, :as => :collectible_entity
  has_many :collection_tax_slabs, :through => :collectible_tax_slabs, :class_name => "TaxSlab"

  has_many :tax_collections, :as => :taxable_entity, :dependent => :destroy
  has_many :tax_fees, :through => :tax_collections, :source => :taxable_fee, :source_type => "InstantFee"
  named_scope :for_category, lambda {|cat_id| {:conditions => {:instant_fee_category_id => cat_id }}}
  named_scope :with_masters, :conditions => "master_fee_particular_id IS NOT NULL"
  named_scope :without_masters, :conditions => {:master_fee_particular_id => nil}
  named_scope :with_ids, lambda {|p_ids| {:conditions => {:id => p_ids} } }
  cattr_accessor :tax_slab_id

  validates_presence_of :name,:amount,:instant_fee_category_id #, :master_fee_particular_id
  validates_numericality_of :amount,:greater_than => 0

  after_create :apply_tax_slab
  before_save :verify_precision
  before_validation :set_particular_name, :if => Proc.new {|x| x.new_record? or x.changed.include?("master_fee_particular_id")}

  def set_particular_name
    self.name = MasterFeeParticular.find_by_id(self.master_fee_particular_id).try(:name)
  end

  def verify_precision
    self.amount = FedenaPrecision.set_and_modify_precision self.amount
  end
  
  def apply_tax_slab slab_id = nil
    self.tax_slab_id = slab_id || self.tax_slab_id
    unless self.tax_slab_id.present?
      self.tax_slabs = []
    else
      tax_slab = TaxSlab.find(self.tax_slab_id)    
      self.tax_slabs = [tax_slab] if tax_slab.present?
    end
  end


  class << self
    def has_unlinked_particulars?
      InstantFeeParticular.count(:conditions => "master_fee_particular_id IS NULL") > 0
    end
  end
end
