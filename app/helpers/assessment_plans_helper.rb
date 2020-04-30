module AssessmentPlansHelper
  def term_duration(term)
    if term.start_date.present? and term.end_date.present?
      duration = (term.end_date.year * 12 + term.end_date.month) - (term.start_date.year * 12 + term.start_date.month)
      start_date = format_date(term.start_date,:format => :long_1)
      end_date = format_date(term.end_date,:format => :long_1)
      "#{start_date} to #{end_date}"
  #    "<b>#{pluralize(duration.to_i,'month')}</b> - #{start_date} to #{end_date}"
    end
  end
end