Gradebook::Reports::Template.config do

  name 'template_a'
  display_name 'Compact 1 Page'
  description 'This template is ideal for a planner having 2-3 terms with 3-4 exams in each term. This 
               compact report format can accommodate upto 2-3 activity sets, term remarks and attendance data in a single page.
              '
  target_type :school
  is_default false

  setting do
    name 'logo'
    kind :select
    options ({'CBSE' => 'cbselogo.png', 'ICSE' => 'icselogo.png', 'Student photo' => 'student_photo', 'none' => ''})
    default_value "cbselogo.png"
  end

  setting do
    name 'header'
    kind :text
    default_value 'Report'
  end
  
  setting do
    name 'theme'
    kind :select
    options ['greyscale','wood', 'indigo', 'ruby', 'wild', 'royale']
    default_value 'indigo'
  end

  setting do
    name 'show_student_photo'
    kind :select
    options ({'Show' => 'yes', "Don't show" => 'no'})
    default_value 'no'
  end
  
  setting do
    name 'watermark'
    kind :select
    options ({'enable' => 'enable', 'disable' => 'disable'})
    default_value 'disable'
  end
  
    setting do
    name 'margin'
    kind :select
    options ({'low' => 'low', 'default' => 'default', 'high' => 'high'})
    default_value 'default'
  end
  
  setting do
    name 'activity_exam_header'
    kind :select
    options ({'term name' => 'term_name', 'exam code' => 'exam_code'})
    default_value 'term_name'
  end
  
end