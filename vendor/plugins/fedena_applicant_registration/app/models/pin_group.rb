class PinGroup < ActiveRecord::Base
  serialize :course_ids
  validates_presence_of :valid_from,:valid_till,:name,:pin_count,:course_ids
  validates_numericality_of :pin_count,:greater_than => 0,:less_than_or_equal_to => 300
  has_many :pin_numbers
  after_create :create_pin_numbers
 
  def validate
    errors.add(:valid_from, :should_be_before_valid_till) \
      if self.valid_from > self.valid_till \
      if self.valid_from and self.valid_till
  end

  def create_pin_numbers
    pin_count.times do
      number = rand.to_s[2..15]
      self.pin_numbers.create(:number => number,:is_active => true)
    end
  end
end