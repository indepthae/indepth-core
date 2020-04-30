class DisciplineComplaint < ActiveRecord::Base
  include CsvExportMod
  belongs_to :user
  has_many :discipline_participations,:dependent=>:destroy
  has_many :discipline_complainees,:dependent=>:destroy
  has_many :discipline_accusations,:dependent=>:destroy
  has_many :discipline_juries,:dependent=>:destroy
  has_many :discipline_members,:dependent=>:destroy
  has_one :discipline_master,:dependent=>:destroy
  has_many :discipline_comments , :as=>:commentable,:dependent=>:destroy
  has_many :discipline_actions,:dependent=>:destroy

  before_save :complaint_modify

  accepts_nested_attributes_for :discipline_participations
  accepts_nested_attributes_for :discipline_complainees,:allow_destroy => true
  accepts_nested_attributes_for :discipline_accusations,:allow_destroy => true
  accepts_nested_attributes_for :discipline_members,:allow_destroy => true
  accepts_nested_attributes_for :discipline_juries,:allow_destroy => true

  validates_uniqueness_of :complaint_no
  validates_presence_of :subject,:body,:complaint_no
  attr_accessor :attachment_file_name
  attr_accessor :attachment_content_type
  attr_accessor :attachment_file_size
  attr_accessor :attachment_updated_at

  def validate
    undestroyed_task_complainee = 0
    undestroyed_task_accusation = 0
    undestroyed_task_juries = 0
    discipline_complainees.each { |t| undestroyed_task_complainee += 1 unless t.marked_for_destruction? }
    errors.add_to_base :complained_by_cant_blank if undestroyed_task_complainee < 1
    discipline_accusations.each { |t| undestroyed_task_accusation += 1 unless t.marked_for_destruction? }
    errors.add_to_base :complained_againist_cant_blank if undestroyed_task_accusation < 1
    discipline_juries.each { |t| undestroyed_task_juries += 1 unless t.marked_for_destruction? }
    errors.add_to_base :jury_cant_blank if undestroyed_task_juries < 1
    if attachment_file_size.present?
      max_size=DisciplineAttachment.new.attachment.instance_variable_get('@max_file_size').to_f
      errors.add_to_base "must be less than 5 MB." if attachment_file_size.to_f > max_size
    end
  end

  def self.sort_discipline(sort_param,c_id)
    if sort_param=="solved"
      if (User.active.find(c_id).admin? )|| self.is_privileged_user(c_id)
        discipline_complaints = self.find(:all,:include=>[:discipline_master],:conditions=>{:action_taken=>true}, :order=>"action_taken DESC")
      elsif (User.active.find(c_id).parent?)
        cmp_ids=DisciplineParticipation.find(:all,:conditions=>{:user_id=>Student.find(Fedena.present_student_id).user_id},:order=>"action_taken DESC").collect(&:discipline_complaint_id).uniq
        discipline_complaints=DisciplineComplaint.find(:all,:conditions=>{:id=>cmp_ids,:action_taken=>true},:order=>"action_taken DESC")
      else
        cmp_ids=DisciplineParticipation.find(:all,:conditions=>{:user_id=>c_id},:order=>"action_taken DESC").collect(&:discipline_complaint_id).uniq
        discipline_complaints=DisciplineComplaint.find(:all,:conditions=>{:id=>cmp_ids,:action_taken=>true},:order=>"action_taken DESC")
      end
    elsif sort_param=="pending"
      if (User.active.find(c_id).admin? )|| self.is_privileged_user(c_id)
        discipline_complaints = self.find(:all,:include=>[:discipline_master],:conditions=>{:action_taken=>false}, :order=>"action_taken ASC")
      elsif (User.active.find(c_id).parent?)
        cmp_ids=DisciplineParticipation.find(:all,:conditions=>{:user_id=>Student.find(Fedena.present_student_id).user_id},:order=>"action_taken ASC").collect(&:discipline_complaint_id).uniq
        discipline_complaints=DisciplineComplaint.find(:all,:conditions=>{:id=>cmp_ids,:action_taken=>false},:order=>"action_taken ASC")
      else
        cmp_ids=DisciplineParticipation.find(:all,:conditions=>{:user_id=>c_id},:order=>"action_taken ASC").collect(&:discipline_complaint_id).uniq
        discipline_complaints=DisciplineComplaint.find(:all,:conditions=>{:id=>cmp_ids,:action_taken=>false},:order=>"action_taken ASC")
      end
    else
      if (User.active.find(c_id).admin? )|| self.is_privileged_user(c_id)
        discipline_complaints = self.find(:all,:include=>[:discipline_master],:order=>"updated_at desc")
      elsif (User.active.find(c_id).parent?)
        cmp_ids=DisciplineParticipation.find(:all,:conditions=>{:user_id=>Student.find(Fedena.present_student_id).user_id},:order=>"updated_at desc").collect(&:discipline_complaint_id).uniq
        discipline_complaints=DisciplineComplaint.find(:all,:conditions=>{:id=>cmp_ids},:order=>"updated_at desc")
      else
        cmp_ids=DisciplineParticipation.find(:all,:conditions=>{:user_id=>c_id},:order=>"updated_at desc").collect(&:discipline_complaint_id).uniq
        discipline_complaints=DisciplineComplaint.find(:all,:conditions=>{:id=>cmp_ids},:order=>"updated_at desc")
      end
    end
    return discipline_complaints
  end
  
  def self.fetch_discipline_complaint_data(params)
  	discipline_complaint_data params
  end

  def self.is_privileged_user(id)
    if User.active.find(id).privileges.include?(Privilege.find_by_name("Discipline"))
      return true
    else
      return false
    end
  end

  def self.cmp_no
    c_nos=self.find(:all,:conditions=>("complaint_no LIKE \"C%\"") ,:order => "id desc").collect(&:complaint_no)
    last_registered_complaint="C1000"
    c_nos.each do |c_no|
      num=c_no.gsub(/\d+/, "").squeeze(" ").strip
      if num=='C'
        last_registered_complaint = c_no.next
        while c_nos.include?(last_registered_complaint)
          last_registered_complaint=last_registered_complaint.next
        end
        break;
      end
    end
    return last_registered_complaint
  end

  def complaint_modify
    self.updated_at=Time.now
  end

  def discipline_participation_user_ids
    discipline_participations.collect(&:user_id)
  end

  def decision_closed?
    return self.action_taken
  end

  def discipline_participations_user_entry
    discipline_participations.collect(&:user)
  end
  
  def discipline_participations_user_include
    (discipline_participations-[discipline_master]).collect(&:user)
  end
  def discipline_participations_exclude_jury_user
    u = Authorization.current_user
    if self.action_taken == true
      if (DisciplineComplaint.is_privileged_user(u.id) ||  u.admin?)
        return true
      else
        s=discipline_participations.collect(&:user)
        user_ids = s.collect{|e| e.id}
        return true if user_ids.include?(u.id)
        return false unless user_ids.include?(u.id)
      end
    else
      v=(discipline_participations-discipline_juries)
      s=(v-[discipline_master]).collect(&:user)
      user_ids = s.collect{|e| e.id}
      return false if user_ids.include?(u.id)
      return true unless user_ids.include?(u.id)
    end
    
  end

end
