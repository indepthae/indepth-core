class GradebookRecordGroup < ActiveRecord::Base
  has_many :gradebook_records, :dependent => :destroy
  belongs_to :assessment_plan
  accepts_nested_attributes_for :gradebook_records, :allow_destroy => true, :reject_if => lambda { |l| l[:record_group_id].blank? }
  default_scope :order=>'priority ASC'
  validates_presence_of :name
  
  def build_records(type,flag)
    records = []
    self.gradebook_records.all(:conditions=>{:record_group_id=>0}).each{|ir| ir.destroy}
    self.reload if flag
    all_records = self.gradebook_records.to_a
    items = AssessmentTerm.all(:conditions=>{:assessment_plan_id=>self.assessment_plan_id}) if type == "AssessmentTerm"
    items = AssessmentGroup.all(:conditions=>["assessment_plan_id=? and (type!=? or is_final_term =? or parent_type=?)",self.assessment_plan_id,"DerivedAssessmentGroup",true,"AssessmentPlan"]) if type == "AssessmentGroup"
    items = AssessmentPlan.all(:conditions=>{:id=>self.assessment_plan_id}) if type == "AssessmentPlan"
    items.each do |item|
      item_record =  all_records.find{|obj| obj.linkable_id == item.id and obj.linkable_type == item.class.to_s and obj.gradebook_record_group_id == self.id}
      records <<  if item_record.present?
        item_record.attributes = {
          :item_name=>item.name,
          :gradebook_record_group_id=>self.id,
          :record_group_id=>item_record.record_group_id,
          :linkable_id=>item.id,
          :linkable_type=>item.class.to_s
        }
        item_record
      else
        gradebook_records.build(
          :item_name=>item.name,
          :gradebook_record_group_id=>self.id,
          :linkable_id=>item.id,
          :linkable_type=>item.class.to_s
        )
      end
    end
    records
  end
  
  def self.save_record_links(params)
    gradebook_record_group = GradebookRecordGroup.find_or_initialize_by_assessment_plan_id(:assessment_plan_id=>params[:assessment_plan_id],:name=>params[:name])
    if gradebook_record_group.new_record?
      gradebook_record_group.save
    else
      gradebook_record_group.update_attributes(:name=>params[:name])
    end
  end
  
  #  def build_gradebook_records(type,plan_id)
  #    items = case type
  #    when "AssessmentTerm"
  #      AssessmentTerm.all(:conditions=>{:assessment_plan_id=>plan_id})
  #    when "AssessmentGroup"
  #      AssessmentGroup.all(:conditions=>{:assessment_plan_id=>plan_id})
  #    when
  #      AssessmentPlan.all(:conditions=>{:id=>plan_id})
  #    end
  #    
  #  end
end