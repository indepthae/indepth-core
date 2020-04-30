class AssessmentScoreImport < ActiveRecord::Base
  before_create :set_status
  after_create :import, :remove_excess_entry
  attr_accessor :students

  serialize :last_message, Hash

  has_attached_file :attachment,
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id/:style/:basename.:extension",
    :max_file_size => 5242880,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types =>[]

#  validates_attachment_content_type :attachment,
#    :content_type =>  %w{text/comma-separated-values,  text/csv,  application/csv, application/excel, application/vnd.ms-excel, application/vnd.msexcel} ,:message=>'File extension is invalid'

  STATUS = {0=> t('in_queue'), 1 => t('importing'), 2 => t('completed'), 3 => t('failed'), 4 => t('partially_completed') }.freeze

  def validate
    begin
      FasterCSV.parse(File.open(self.attachment.to_file.path))
    rescue FasterCSV::MalformedCSVError => e
      self.errors.add(:attachment_content_type, "File extension is invalid")
    end
  end

  def set_status
    self.status = 0
  end

  def import
    AssessmentScoreImportService.new(self.id).delayed_import
  end

  def status_text
    STATUS[self.status]
  end

  def add_empty_file_error
    errors.add(:attachment_content_type, :blank)
  end

  def remove_excess_entry
    imports = AssessmentScoreImport.all(:conditions => {:assessment_group_id => self.assessment_group_id, :batch_id => self.batch_id})
    imports.first.destroy if imports.count > 15
  end

  def self.default_time_zone_present_time(time_stamp)
    server_time = time_stamp
    server_time_to_gmt = server_time.getgm
    local_tzone_time = server_time
    time_zone = Configuration.find_by_config_key("TimeZone")
    unless time_zone.nil?
      unless time_zone.config_value.nil?
        zone = TimeZone.find_by_id(time_zone.config_value)
        if zone.present?
          local_tzone_time = if zone.difference_type == "+"
            server_time_to_gmt + zone.time_difference
          else
            server_time_to_gmt - zone.time_difference
          end
        end
      end
    end
    return local_tzone_time
  end

end
