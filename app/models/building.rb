class Building < ActiveRecord::Base
  has_many :classrooms, :dependent => :destroy
  validates_presence_of :name
  validates_uniqueness_of :name,:scope=> [:is_deleted],:if=> 'is_deleted == false'
  accepts_nested_attributes_for :classrooms, :allow_destroy => true
  
  def presence_of_rooms
    errors.add_to_base :should_have_an_initial_classroom if classrooms.length == 0
  end
end
