Gradebook::Reports::Template.config do

  name 'template_d'
  display_name 'Long Form Skill Report' # Two Page
  description 'This template is ideal for a planner having 2-3 terms with 3-4 exams in each term. It 
               shows subject exams and skill exams in two distinct tables.
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
    name 'theme'
    kind :select
    options ['wood', 'indigo', 'ruby', 'wild', 'royale']
    default_value 'wood'
  end

  setting do
    name 'header'
    kind :text
    default_value 'Report'
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
  
end