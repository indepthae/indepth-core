class AttendanceLabel < ActiveRecord::Base
  has_many   :attendances
  has_many   :subject_leaves

  validates_presence_of    :name, :attendance_type, :code
  validates_length_of     :code, :maximum => 2
  validates_uniqueness_of :name , :case_sensitive => false ,:message => "is already taken"
  validates_uniqueness_of :code , :case_sensitive => false, :message => "is already taken"

  def self.create_default_labels
    unless exists?
      Configuration.set_value("CustomAttendanceType", "0")
      [{:name => 'Present', :code => 'P', :attendance_type => 'Present', :is_default => true},
        {:name => 'Missed', :code => 'M', :attendance_type => 'Absent', :is_default => true},
        {:name => 'Tardy', :code => 'L', :attendance_type => 'Late', :is_default => true}
      ].each do |param|
        AttendanceLabel.find_or_create_by_name(param)
      end
    end
    all
  end

  



  def full_name
    "#{attendance_type}(#{code})"
  end

end
