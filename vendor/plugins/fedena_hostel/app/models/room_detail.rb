
class RoomDetail < ActiveRecord::Base
  cattr_reader :per_page
  @@per_page = 20

  belongs_to :hostel
  has_many   :room_allocation,:dependent=>:destroy
  has_many :hostel_room_additional_details, :as=>:linkable,:dependent => :destroy
  accepts_nested_attributes_for :hostel_room_additional_details, :allow_destroy=>true

  validates_presence_of :hostel_id, :room_number, :students_per_room, :rent
  validates_uniqueness_of :room_number, :scope => :hostel_id
  validates_numericality_of :students_per_room,:less_than_or_equal_to=>30,:allow_nil=>true
  before_save :verify_precision
  after_save :delete_nil_additional_details
  
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

  def verify_precision
    self.rent = FedenaPrecision.set_and_modify_precision self.rent
  end

  def get_room_allocation
    return RoomAllocation.find_all_by_room_detail_id(self.id, :conditions=>["is_vacated is false"])
  end

  def self.room_list(parameters)
    sort_order=parameters[:sort_order]
    type=parameters[:type]
    hostel_id=parameters[:hostel_id]
    if type.nil?
      if sort_order.nil?
        rooms=RoomDetail.all(:select=>"hostel_id,rent,room_details.id,room_number,students_per_room,(students_per_room-count(IF(is_vacated=0,1,NULL))) as available" ,:joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'room_number',:conditions=>{:hostel_id=>hostel_id},:order=>'room_number ASC')
      else
        rooms=RoomDetail.all(:select=>"hostel_id,rent,room_details.id,room_number,students_per_room,(students_per_room-count(IF(is_vacated=0,1,NULL))) as available" ,:joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'room_number',:conditions=>{:hostel_id=>hostel_id},:order=>sort_order)
      end
    else
      if type=='available'
        if sort_order.nil?
          rooms=RoomDetail.all(:select=>"hostel_id,rent,room_details.id,room_number,students_per_room,(students_per_room-count(IF(is_vacated=0,1,NULL))) as available" ,:joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'room_number',:conditions=>{:hostel_id=>hostel_id},:having=>'available > 0',:order=>'room_number ASC')
        else
          rooms=RoomDetail.all(:select=>"hostel_id,rent,room_details.id,room_number,students_per_room,(students_per_room-count(IF(is_vacated=0,1,NULL))) as available" ,:joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'room_number',:conditions=>{:hostel_id=>hostel_id},:having=>'available > 0',:order=>sort_order)
        end
      else
        if sort_order.nil?
          rooms=RoomDetail.all(:select=>"hostel_id,rent,room_details.id,room_number,students_per_room,(students_per_room-count(IF(is_vacated=0,1,NULL))) as available" ,:joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'room_number',:conditions=>{:hostel_id=>hostel_id},:having=>'available = 0',:order=>'room_number ASC')
        else
          rooms=RoomDetail.all(:select=>"hostel_id,rent,room_details.id,room_number,students_per_room,(students_per_room-count(IF(is_vacated=0,1,NULL))) as available" ,:joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'room_number',:conditions=>{:hostel_id=>hostel_id},:having=>'available = 0',:order=>sort_order)
        end
      end
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('room_details.room_number')}","#{t('room_details.students_per_room') }","#{t('room_details.availability') }","#{t('room_details.rent')}"]
    data << col_heads
    rooms.each_with_index do |s,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{s.room_number}"
      col<< "#{s.students_per_room}"
      col<< "#{s.available}"
      col<< "#{s.rent}"
      col=col.flatten
      data<< col
    end
    return data
  end

end
