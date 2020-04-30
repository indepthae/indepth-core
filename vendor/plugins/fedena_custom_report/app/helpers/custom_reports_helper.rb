# To change this template, choose Tools | Templates
# and open the template in the editor.

module CustomReportsHelper 
  def t(str)
    if str.to_s.include?("_additional_fields_")
      str.to_s.split('_additional_fields_').first.to_s.gsub("_"," ").titleize
    elsif str.to_s.include?("_bank_fields_")
      str.to_s.split('_bank_fields_').first.to_s.gsub("_"," ").titleize
    else
     super(str,:default=>str.to_s.titleize)
    end
  end
end
