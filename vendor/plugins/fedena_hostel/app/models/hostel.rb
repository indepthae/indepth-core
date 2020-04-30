class Hostel < ActiveRecord::Base
  before_destroy :check_allocation
  has_many :wardens,:dependent=>:destroy
  has_many :room_details,:dependent=>:destroy
  has_many :hostel_room_additional_details, :as=>:linkable,:dependent => :destroy
  accepts_nested_attributes_for :hostel_room_additional_details, :allow_destroy=>true
  validates_presence_of :name, :hostel_type
  validates_uniqueness_of :name ,:scope => :hostel_type,:message => :unique_name_with_same_hostel_type
  validates_inclusion_of :hostel_type, :in => ["Common", "Gents","Ladies"]
  after_save :delete_nil_additional_details
  validate :validates_type_change
  
  def delete_nil_additional_details
    self.hostel_room_additional_details.each do |detail|
      detail.destroy if detail.additional_info.nil? or detail.additional_info.blank?
    end
  end

  def hostel_room_additional_details_attributes=(attrs)
    unless self.new_record?
      attrs.each{|k,attr|
        (attrs[k]['_delete']=true if (attrs[k]['additional_info'].blank? and HostelRoomAdditionalField.find_by_id(attr['hostel_room_additional_field_id']).is_mandatory==false) if attrs[k]['additional_info'].is_a? String)
        (attrs[k]['additional_info'].each_with_index{|v,i| attrs[k]['additional_info'][i] = nil if v.blank?}
          attrs[k]['_delete']=true if (attr['additional_info'].compact.blank? and HostelRoomAdditionalField.find_by_id(attr['hostel_room_additional_field_id']).is_mandatory==false)
          attrs[k]['additional_info'] = attr['additional_info'].compact.join(',')) if attr['additional_info'].is_a? Array
      }
    else
      attrs.each{|k,attr|
        (attrs[k]['additional_info']=nil if attrs[k]['additional_info'].blank?) if attrs[k]['additional_info'].is_a? String
        (attrs[k]['additional_info'].each_with_index{|v,i| attrs[k]['additional_info'][i] = nil if v.blank?}
          attrs[k]['additional_info'] = attr['additional_info'].compact.join(',')) if attr['additional_info'].is_a? Array
      }
    end
    assign_nested_attributes_for_collection_association(:hostel_room_additional_details, attrs)
  end

  def check_allocation
    self.room_details.each do |r|
      vacant = RoomAllocation.find_all_by_room_detail_id(r.id, :conditions=>["is_vacated is false"])
      unless vacant.size == 0
        errors.add_to_base :cant_delete_hostel_allocated
        return false
      end
    end
  end
  
  def validates_type_change
    if self.hostel_type_changed?
      errors.add_to_base :cant_update_hostel_type_allocated if self.is_allocated?
    end
  end
  
  def is_allocated?
    status = false
    self.room_details.each do |r|
      vacant = RoomAllocation.find_all_by_room_detail_id(r.id, :conditions=>["is_vacated is false"])
      unless vacant.size == 0
        status = true
      end
    end
    return status
  end


end
