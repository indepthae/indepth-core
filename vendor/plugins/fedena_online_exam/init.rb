require 'translator'
require File.join(File.dirname(__FILE__), "lib", "fedena_online_exam")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")
require 'dispatcher'


FedenaPlugin.register = {
  :name=>"fedena_online_exam",
  :description=>"Fedena Online Exam Module",
  :auth_file=>"config/online_exam_auth.rb",
  :more_menu=>{:title=>"online_exam_text",:controller=>"online_student_exam",:action=>"index",:target_id=>"more-parent"},
  :sub_menus=>[{:title=>"online_exam_text",:controller=>"online_exam",:action=>"index",:target_id=>"exam-parent"}],
  :online_exam_index_link=>[{:title=>"online_exam_text",:destination=>{:controller=>"online_exam",:action=>"index"},:description=>"manage_online_exam_system"},{:title=>"evaluate_online_exam",:destination=>{:controller=>"online_exam",:action=>"evaluator_home"},:description=>"evaluate_online_exam_description"}],
  :multischool_models=>%w{OnlineExamAttendance OnlineExamGroup OnlineExamOption OnlineExamQuestion OnlineExamScoreDetail OnlineExamGroupsQuestion}
  

}

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

FedenaOnlineExam.attach_overrides

if RAILS_ENV == 'development'
  ActiveSupport::Dependencies.load_once_paths.reject!{|x| x =~ /^#{Regexp.escape(File.dirname(__FILE__))}/}
end

