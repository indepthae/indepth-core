class TemplateCustomField < ActiveRecord::Base
  belongs_to :corresponding_template, :polymorphic => true
end
