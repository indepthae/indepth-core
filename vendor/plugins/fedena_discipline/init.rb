require 'translator'
require File.join(File.dirname(__FILE__), "lib", "fedena_discipline")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")
require 'dispatcher'
FedenaPlugin.register = {
  :name=>"fedena_discipline",
  :auth_file => "config/discipline_auth.rb",
  :description=>"Fedena Discipline",
  :more_menu=>{:title=>"discipline",:controller=>"discipline_complaints",:action=>"index",:target_id=>"more-parent"},
  :multischool_models=>%w{DisciplineComplaint DisciplineParticipation DisciplineComment DisciplineAction DisciplineAttachment}
}

FedenaDiscipline.attach_overrides

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end