class DisciplineComment < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :commentable , :polymorphic=> true
  has_many :replies , :as=>:commentable, :class_name=>'DisciplineComment',:dependent=>:destroy

end
