module AcademicYearsHelper
  
  def fetch_path(a_year)
    a_year.new_record? ? academic_years_path : academic_year_path
  end
  
end
