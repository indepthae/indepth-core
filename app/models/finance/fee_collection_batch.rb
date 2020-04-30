class FeeCollectionBatch < ActiveRecord::Base
  belongs_to :batch
  belongs_to :finance_fee_collection
  has_many :collection_particulars,
    :finder_sql=>'select cp.* from collection_particulars cp inner join finance_fee_particulars ffp on ffp.id=cp.finance_fee_particular_id where cp.finance_fee_collection_id=#{finance_fee_collection_id} and ffp.batch_id=#{batch_id}',
    :dependent=>:destroy
  has_many :collection_discounts,
    :finder_sql=>'select cd.* from collection_discounts cd inner join fee_discounts fd on fd.id=cd.fee_discount_id where cd.finance_fee_collection_id=#{finance_fee_collection_id} and fd.batch_id=#{batch_id}',
    :dependent=>:destroy
  before_destroy :delete_finance_fees
  after_create :create_associates
  attr_accessor :tax_mode
  
  validates_uniqueness_of :finance_fee_collection_id,:scope=>:batch_id

  named_scope :current_active_financial_year, lambda {|x|
                {:joins => {:finance_fee_collection => :fee_category},
                 :conditions => ["finance_fee_categories.financial_year_id
                                  #{FinancialYear.current_financial_year_id.present? ? '=' : 'IS'} ?",
                                  FinancialYear.current_financial_year_id] }}

  private

  
  def create_associates
    tax_config = tax_mode || 0
    discounts=FeeDiscount.find_all_by_finance_fee_category_id_and_batch_id(finance_fee_collection.fee_category_id,
      batch_id,:conditions=>"is_deleted=0 and is_instant=false")
    discounts.each do |discount|
      CollectionDiscount.create(:fee_discount_id=>discount.id,:finance_fee_collection_id=>finance_fee_collection_id)
    end
    include_associations = tax_config ? [] : [:tax_slabs]
    particlulars = FinanceFeeParticular.find_all_by_finance_fee_category_id_and_batch_id(
      finance_fee_collection.fee_category_id,batch_id, :conditions=>"is_deleted=0",
      :include => include_associations)
    particlulars.each do |particular|
      CollectionParticular.create(:finance_fee_particular_id=>particular.id,:finance_fee_collection_id=>finance_fee_collection_id)
      #particular wise tax recording while collection is created or modified
      particular.collectible_tax_slabs.create({ :tax_slab_id => particular.tax_slabs.try(:last).try(:id),
          :collection_id => finance_fee_collection_id, :collection_type => 'FinanceFeeCollection' 
        }) if tax_config && particular.tax_slabs.present?
    end   
  end
  
  def load_tax_config
    Configuration.get_config_value('EnableFinanceTax').to_i
  end
  
  def delete_finance_fees
    FinanceFee.find(:all,:conditions=>"finance_fees.batch_id=#{batch_id} and finance_fees.fee_collection_id=#{finance_fee_collection_id}").each{|fee| fee.destroy}
  end
end
