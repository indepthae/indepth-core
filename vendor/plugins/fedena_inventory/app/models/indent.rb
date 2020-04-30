class Indent < ActiveRecord::Base
  attr_accessor :raise_purchase_order

  belongs_to :user
  belongs_to :store
  belongs_to :manager, :class_name => "User"
  has_one :purchase_order
  has_many :indent_items, :dependent => :destroy


  validates_presence_of :indent_no, :store_id, :user_id,:indent_items
  validates_inclusion_of :status,  :in => %w(Pending Issued Rejected)

  named_scope :active,{ :conditions => { :is_deleted => false }}
  named_scope :inactive,{ :conditions => { :is_deleted => true }}

  accepts_nested_attributes_for :indent_items, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true
  
  def validate
    if Indent.active.reject{|i| i.id == id }.find_by_indent_no(indent_no).present?
      errors.add("indent_no","is already taken")
    end
    to_check = indent_items.reject{|ii| ii._destroy == true}
    unless to_check.present?
      errors.add('indent_items',"can't be blank")
    end
  end
  
  def can_be_deleted?
    (purchase_order.present? and purchase_order.is_deleted == false) ? false : true
  end
  
  def get_manager
    user.admin? ? user.id : user.employee_record.nil? ? nil : user.employee_record.reporting_manager.nil? ? nil : user.employee_record.reporting_manager.try(:id)
  end

  def get_purchase_order
    po = purchase_order
    po ||= build_purchase_order(:store_id => store_id, :po_no => "P#{indent_no}",:po_date => DateTime.now)
  end

  def accept_indent(params)
    notice = ""
    params = params.merge(:manager_id => get_manager)
    params.delete(:status)
    purchase_order_record = get_purchase_order
    if update_attributes(params)
      indent_items.each do |i|
        if i.store_item.quantity >= i.required
          i.issue_indent_item
          notice <<  " #{ i.required } #{i.store_item.item_name} Available and Issued. "
        else
          if self.raise_purchase_order.to_s == "1"
            quantity = (i.store_item.quantity - i.required)
            i.issue_indent_item
            purchase_order_record.purchase_items.build(:store_item_id => i.store_item_id, :quantity => (quantity).abs, :discount=> 0, :tax=>0,:price => i.store_item.unit_price )
            notice <<  " Purchase Order #{purchase_order.po_no} raised for #{ (quantity).abs } #{i.store_item.item_name}. "
          else
            quantity = (i.store_item.quantity - i.required)
            i.issue_indent_item
            notice <<  " Purchase Order needed for #{ (quantity).abs } #{i.store_item.item_name}. "
          end
        end
      end
      if purchase_order_record.purchase_items.present?
        if purchase_order_record.save
          notice << "Purchase order raised/updated successfully."
          notice
        else
          errors.add("purchase_order","#{purchase_order.errors.full_messages}")
        end
      else
        notice
      end
    else
      false
    end
  end

  def purchase_order_required?
    indent_items.map{|i| i.required.present? and i.store_item.quantity >= i.required}.reject{|r| r == true}.present?
  end

  def fully_served?
    indent_items.map(&:pending).reject{|i| i == 0}.blank?
  end

  def accept
    update_attributes(:status => "Issued") if fully_served?
  end

  def can_accept_edit_or_delete(user_in_question)
    user_in_question.id == user_id or user_in_question.id == manager_id or user_in_question.privileges.map(&:name).include?('InventoryManager') or user_in_question.privileges.map(&:name).include?('Inventory') or user_in_question.admin?
  end

  def can_accept(user_in_question)
    user_in_question.privileges.map(&:name).include?('Inventory') or user_in_question.privileges.map(&:name).include?('InventoryManager') or user_in_question.admin? or user_in_question.id == manager_id
  end

  def reject_indent(params)
    params = params.merge(:manager_id => get_manager)
    update_attributes(params)
    notice = ""
    notice << "Indent rejected successfully"
  end

  def self.indent_details(parameters)
    sort_order=parameters[:sort_order]
    status=parameters[:status]
    if sort_order.nil?
      if status[:sort_type]=="all"
        indents=Indent.all(:select=>"indents.*,users.first_name,users.last_name,managers_indents.first_name as m_first_name,managers_indents.last_name as m_last_name",:joins=>"LEFT OUTER JOIN `users` ON `users`.id = `indents`.user_id LEFT OUTER JOIN `users` managers_indents ON `managers_indents`.id = `indents`.manager_id",:conditions=>["indents.created_at >= ? and indents.created_at <= ? and indents.is_deleted='0'",status[:from].to_date.beginning_of_day,status[:to].to_date.end_of_day],:order=>'indent_no')
      else
        indents=Indent.all(:select=>"indents.*,users.first_name,users.last_name,managers_indents.first_name as m_first_name,managers_indents.last_name as m_last_name",:joins=>"LEFT OUTER JOIN `users` ON `users`.id = `indents`.user_id LEFT OUTER JOIN `users` managers_indents ON `managers_indents`.id = `indents`.manager_id",:conditions=>["indents.status LIKE ? and indents.created_at >= ? and indents.created_at <= ? and indents.is_deleted='0'",status[:sort_type],status[:from].to_date.beginning_of_day,status[:to].to_date.end_of_day],:order=>'indent_no')
      end
    else
      if status[:sort_type]=="all"
        indents=Indent.all(:select=>"indents.*,users.first_name,users.last_name,managers_indents.first_name as m_first_name,managers_indents.last_name as m_last_name",:joins=>"LEFT OUTER JOIN `users` ON `users`.id = `indents`.user_id LEFT OUTER JOIN `users` managers_indents ON `managers_indents`.id = `indents`.manager_id",:conditions=>["indents.created_at >= ? and indents.created_at <= ? and indents.is_deleted='0'",status[:from].to_date.beginning_of_day,status[:to].to_date.end_of_day],:order=>sort_order)
      else
        indents=Indent.all(:select=>"indents.*,users.first_name,users.last_name,managers_indents.first_name as m_first_name,managers_indents.last_name as m_last_name",:joins=>"LEFT OUTER JOIN `users` ON `users`.id = `indents`.user_id LEFT OUTER JOIN `users` managers_indents ON `managers_indents`.id = `indents`.manager_id",:conditions=>["indents.status LIKE ? and indents.created_at >= ? and indents.created_at <= ? and indents.is_deleted='0'",status[:sort_type],status[:from].to_date.beginning_of_day,status[:to].to_date.end_of_day ],:order=>sort_order)
      end
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('indent_no')}","#{t('raised') }","#{t('expected_date') }","#{t('status')}","#{t('manager')}"]
    data << col_heads
    indents.each_with_index do |s,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{s.indent_no}"
      col<< "#{s.first_name} #{s.last_name}"
      col<< "#{s.expected_date.to_date}"
      col<< "#{s.status}"
      col<< "#{s.m_first_name} #{s.m_last_name}"
      col=col.flatten
      data<< col
    end
    return data
  end

end
