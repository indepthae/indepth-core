require 'dispatcher'
require 'fedena_data_palette/palette_text'
require File.join(File.dirname(__FILE__), "lib", "fedena_data_palette")

FedenaPlugin.register = {
  :name=>"fedena_data_palette",
  :description=>"Fedena Data palettes",
  :auth_file=>"config/data_palette_auth.rb",
  :multischool_models=>%w{UserPalette},
  :general_models=>%w{Palette}
}


Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

Dispatcher.to_prepare :fedena_data_palette do
  User.send(:has_many, :user_palettes)
  User.send(:has_many, :palettes, :through=>:user_palettes)
  News.send :include, FedenaDataPalette::NewsPaletteText
  Event.send :include, FedenaDataPalette::EventsPaletteText
  Student.send :include, FedenaDataPalette::StudentsPaletteText
  ArchivedStudent.send :include, FedenaDataPalette::ArchivedStudentsPaletteText
  Employee.send :include, FedenaDataPalette::EmployeesPaletteText
  ArchivedEmployee.send :include, FedenaDataPalette::ArchivedEmployeesPaletteText
  EmployeeAttendance.send :include, FedenaDataPalette::EmployeeAttendancePaletteText
  Exam.send :include, FedenaDataPalette::ExamPaletteText
  ApplyLeave.send :include, FedenaDataPalette::ApplyLeavePaletteText
  SmsLog.send :include, FedenaDataPalette::SmsPaletteText
  FinanceTransaction.send :include, FedenaDataPalette::FinancePaletteText
  TimetableEntry.send :include, FedenaDataPalette::TimetablePaletteText
  Task.send :include, FedenaDataPalette::TaskPaletteText if FedenaPlugin.plugin_installed?("fedena_task")
  GroupPost.send :include, FedenaDataPalette::DiscussionPaletteText if FedenaPlugin.plugin_installed?("fedena_discussion")
  BlogPost.send :include, FedenaDataPalette::BlogPaletteText if FedenaPlugin.plugin_installed?("fedena_blog")
  PollQuestion.send :include, FedenaDataPalette::PollPaletteText if FedenaPlugin.plugin_installed?("fedena_poll")
  BookMovement.send :include, FedenaDataPalette::LibraryPaletteText if FedenaPlugin.plugin_installed?("fedena_library")
  OnlineMeetingRoom.send :include, FedenaDataPalette::OnlineMeetingPaletteText if FedenaPlugin.plugin_installed?("fedena_bigbluebutton")
  Placementevent.send :include, FedenaDataPalette::PlacementPaletteText if FedenaPlugin.plugin_installed?("fedena_placement")
  GalleryPhoto.send :include, FedenaDataPalette::GalleryPaletteText if FedenaPlugin.plugin_installed?("fedena_gallery")
  User.send :include, FedenaDataPalette::BirthdayPaletteText
  User.send :include, FedenaDataPalette::UserMethod
  Attendance.send :include, FedenaDataPalette::AttendancePaletteText
  UserController.send :include, FedenaDataPalette::DashboardOverride
end
