class Fine < ActiveRecord::Base
  belongs_to :user
  has_many :finance_fee_collections
  has_many :fine_rules
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:is_deleted], :if => 'is_deleted == false'
  validates_format_of :name, :with => /^\S.*\S$/i, :message => :should_not_contain_white_spaces_at_the_beginning_and_end
  validate :uniqueness_fine_days

  accepts_nested_attributes_for :fine_rules, :allow_destroy => true

  named_scope :active, {:conditions => {:is_deleted => false}}
  # validates_associated :fine_rules
  validate :mark_fine_slabs_for_removal

  def mark_fine_slabs_for_removal
    fine_rules.each do |fine_rule|
      if (fine_rule._destroy == true)
        if Fine.finance_fee_collection_dependancy_exists(fine_rule) or Fine.transport_fee_collection_dependancy_exists(fine_rule)
          errors.add_to_base(t('cant_delete_fee_collection_assigned'))
          false
        else
          fine_rule.mark_for_destruction
        end
      end
    end
  end


  def uniqueness_fine_days
    hash = {}
    fine_rules.each do |child|
      if hash[child.fine_days]
        errors.add(:fine_days, :taken) if errors[:fine_days].blank?
      end
      hash[child.fine_days]=true
    end
  end
  
  def self.finance_fee_collection_dependancy_exists(fine_rule)
    Fine.find(:first,:joins=>:finance_fee_collections,:conditions=>"fines.id='#{fine_rule.fine_id}' and finance_fee_collections.is_deleted = false and finance_fee_collections.created_at >= '#{fine_rule.created_at}'").present?
  end  
      
  def self.transport_fee_collection_dependancy_exists(fine_rule)
    FedenaPlugin.can_access_plugin?('fedena_transport') ? Fine.find(:first,:joins=>:transport_fee_collections,:conditions=>"fines.id='#{fine_rule.fine_id}' and transport_fee_collections.is_deleted = false and transport_fee_collections.created_at >= '#{fine_rule.created_at}'").present? : false
  end
    
  end
