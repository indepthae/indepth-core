Gradebook::Reports::Template.config do

  name 'template_h'
  display_name 'Activity Exam Template'
  description ' '
  target_type :school
  schools [] 
  is_default false

 setting do
    name 'logo'
    kind :select
    options ({'cbse' => "cbselogo.png", 'icse' => "icselogo.png", 'none' => ''})
    default_value "cbselogo.png"
  end

  setting do
    name 'header'
    kind :text
    default_value 'Report'
  end

  setting do
    name 'margin'
    kind :select
    options ({'low' => 'low', 'default' => 'default', 'high' => 'high'})
    default_value 'default'
  end
  
end