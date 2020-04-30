Gradebook::Reports::Template.config do

  name 'template_c'
  display_name 'Simple 2 Term Template' #'Single Page'
  description 'Ideal for planners with 2 terms and upto 3 exams per term and an final end of year 
               result. It can also accommodate upto 2 activity sets along with a term wise remark 
               set and attendance. It also features an optional student final marks vs batch average marks graph.
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
    options ['greyscale','wood', 'indigo', 'ruby', 'wild', 'royale']
    default_value 'greyscale'
  end

  setting do
    name 'show_student_photo'
    kind :select
    options ({'Show' => 'yes', "Don't show" => 'no'})
    default_value 'no'
  end
  
  setting do
    name 'graph'
    kind :select
    options ['enable','disable']
    default_value 'enable'
  end

  setting do
    name 'header'
    kind :text
    default_value 'ANNUAL REPORT CARD'
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