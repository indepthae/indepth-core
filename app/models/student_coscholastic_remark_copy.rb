class StudentCoscholasticRemarkCopy < ActiveRecord::Base
  belongs_to :student
  belongs_to :batch
  belongs_to :observation
end
