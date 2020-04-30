module FinanceReportsHelper
  def error_message_box(error_msg)
    "<div class='wrapper'><div class='error-icon'></div><div class='error-msg'>#{error_msg}</div></div>" if error_msg.present?
  end

  # course options in reporting filters
  def courses_options args = {}
    options = []
    options << ["#{t('select_a_course')}", ""] if args[:prompt]
    options << [t('select_all'), 'all'] if args[:select_all]
    options += @courses.map { |c| [c.course_name, c.id] }
    options.compact
  end

  # returns (,) separated list of batches for every student record (as per master reporting data)
  def student_batch_names student_rec, report_hash = nil
    report_hash ||= @report_hash
    batch_ids = student_rec.batch_ids.split(",").map(&:to_i)
    batch_ids.inject([]) do |batch_names, b_id|
      batch_names << report_hash[:batches][b_id].try(:last).full_name
      batch_names
    end.join(",")
  end

  def page_counter
    page = (params[:page].to_i - 1)
    (page > 0 ? page : 0) * @per_page
  end

  def display_amount amt
    amt.is_a?(Hash) ? '-' : precision_label(amt) || '-'
  end
  
  def options_from_collection_for_select_account(collection, value_method, text_method, selected = nil)
    options = collection.map do |element|
      [element.send(text_method), element.send(value_method)]
    end
    options << ["#{t('default_fee_account')}", 0]
    options = options.sort_by { |a, b| b }
    selected, disabled = extract_selected_and_disabled(selected)
    select_deselect = {}
    select_deselect[:selected] = extract_values_from_collection(collection, value_method, selected)
    select_deselect[:disabled] = extract_values_from_collection(collection, value_method, disabled)

    options_for_select(options, select_deselect)
  end
      
end
