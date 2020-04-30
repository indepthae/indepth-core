# finds menu link with name online_exam and removes them
online_exams = MenuLink.find_all_by_name('online_exam')
if !online_exams.empty?
  online_exams.each do |online_exam|
    online_exam.destroy
  end
end