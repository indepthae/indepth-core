class FinanceReport
  cattr_accessor :report_columns, :default_headers
  extend FinanceReportsHelper

  class << self

    def generate_report report_type, report_format, args
      search_params = extract_params args
      report_data = generate_report_data report_type, search_params
      return report_data unless report_format == 'csv'

      report_data[:expected_amount] = search_params[:expected_amount]
      generate_csv_data report_type, report_data
    end

    def generate_report_data report_type, search_params
      send "#{report_type}_data", search_params
    end

    def extract_params args
      params_h = {:start_date => args[:start_date], :end_date => args[:end_date], :course_id => args[:course_id],
       :financial_year_id => args[:financial_year_id], :fetch_all => true}
      params_h[:batch_id] = args[:batch_id] if args[:batch_id].present?
      params_h[:fee_account_ids] = args[:fee_account_ids] if args[:fee_account_ids].present?
      params_h[:expected_amount] = 1 unless args[:expected_amount].to_i.zero?

      params_h
    end

    def particular_wise_daily_data search_params
      MasterParticularReport.search(search_params.merge({:search_method => 'particular_wise_daily_transaction'}))
    end

    def particular_wise_student_data search_params
#      puts search_params.inspect
      MasterParticularReport.search(search_params.merge({:search_method => 'particular_wise_student_transaction'}))
    end

    def payment_mode_batch_wise_data search_params
      MasterParticularReport.search(search_params.merge({:search_method => 'payment_mode_summary_transaction',
                                                         :mode => 'batch_wise'}))
    end

    def payment_mode_particular_wise_data search_params
      MasterParticularReport.search(search_params.merge({:search_method => 'payment_mode_summary_transaction',
                                                         :mode => 'particular_wise'}))

    end

    def generate_csv_data report_type, report_data
      csv_data = FasterCSV.generate do |csv|
        # filters
        csv << I18n.t("finance_reports.finance_reports_#{report_type}")
        csv << ""
        csv << [I18n.t("financial_year_name"), report_data[:financial_year_name]]
        csv << [I18n.t('date_range_text'), format_date(report_data[:start_date]), I18n.t('to'), format_date(report_data[:end_date])]
        csv << [I18n.t('fee_account_text'), report_data[:fee_account_names]] # add course name && batch details
        csv << [I18n.t('courses_text'), report_data[:course_names], I18n.t('batches_text'), report_data[:batch_names]] # add course name && batch details
        csv << ""
      end

      csv_data + (send "#{report_type}_csv", report_data)
    end

    def particular_wise_daily_csv report_data
      FasterCSV.generate do |csv|
        row = [I18n.t('sl_no'), I18n.t('date_text'), I18n.t('total')]
        report_data[:particulars].each_pair do |pi, pname|
          row << pname
        end
        csv << row
        csv << ""
        report_data[:dates].each_with_index do |date, i|
          d = date.date
          row = [(i+1), format_date(d), report_data[:particulars_data][d][:total]]
          report_data[:particulars].each_pair do |pi, pname|
            v = report_data[:particulars_data][d][:particular_totals][pi]
            row << (v.is_a?(Hash) ? '-' : FedenaPrecision.set_and_modify_precision(v))
          end
          csv << row
        end
        row = [I18n.t('grand_total'),'', report_data[:grand_totals][:total]]
        report_data[:particulars].each_pair do |pi, pname|
          row << report_data[:grand_totals][:particular_totals][pi]
        end
        csv << row
      end
    end

    def particular_wise_student_csv report_data
      FasterCSV.generate do |csv|
        row = [I18n.t('sl_no'), I18n.t('student_name'), I18n.t('batch_names'), I18n.t('finance_reports.total_paid')]
        next_row = ["","","",""]
        expected_head = [I18n.t('finance_reports.expected_amount'), I18n.t('finance_reports.paid_amount'), I18n.t('finance_reports.balance_amount')]
        report_data[:particulars].each_pair do |pi, pname|
          row << pname
          if report_data[:expected_amount]
            row += ["",""] unless pname == 'Fine'
            next_row += pname != 'Fine' ? expected_head : [""]
          end
        end
        csv << row
        csv << next_row if report_data[:expected_amount]
        csv << ""
        report_data[:students].each_with_index do |student, i|
          row = [(i+1), "#{student.full_name} (#{student.admission_no})", student_batch_names(student, report_data),
                 report_data[:students_data][student.id][:total]]
          report_data[:particulars].each_pair do |pi, pname|
            v2 = report_data[:students_data][student.id][:particular_totals][pi]
            arr = (v2.is_a?(Hash) ? '-' : FedenaPrecision.set_and_modify_precision(v2) || '-').to_a
            if report_data[:expected_amount] and pname != 'Fine'
              v1 = report_data[:students_data][student.id][:expected_particular_totals][pi]
              v3 = report_data[:students_data][student.id][:balance_particular_totals][pi]
              arr.unshift(v1)
              arr << v3
            end
            row += arr
          end
          csv << row
        end

        row = [I18n.t('grand_total'),'', '', report_data[:grand_totals][:total]]
        # puts report_data.inspect
        report_data[:particulars].each_pair do |pi, pname|
          v2 = report_data[:grand_totals][:particular_totals][pi]
          arr = v2.to_a
          if report_data[:expected_amount] and pname != 'Fine'
            v1 = report_data[:grand_totals][:expected_particular_totals][pi]
            v3 = v1 - v2
            arr.unshift(v1)
            arr << v3
          end
          row += arr
        end
        csv << row
      end
    end

    def payment_mode_batch_wise_csv report_data
      FasterCSV.generate do |csv|
        row = [I18n.t('sl_no'), I18n.t('batch_text'), I18n.t('total')]
        report_data[:payment_modes_list].each do |mode_name|
          row << mode_name
        end
        csv << row
        csv << ""
        report_data[:batches].each_with_index do |batch, i|
          row = [(i+1), batch.full_name, report_data[:payment_modes_data][batch.id][:total]]
          report_data[:payment_modes_list].each do |mode_name|
            v = report_data[:payment_modes_data][batch.id][:mode_totals][mode_name] || '-'
            row << (v.is_a?(Hash) ? '-' : FedenaPrecision.set_and_modify_precision(v))
          end
          csv << row
        end
        row = [I18n.t('grand_total'),'', report_data[:grand_totals][:total]]
        report_data[:payment_modes_list].each do |mode_name|
          row << report_data[:grand_totals][:mode_totals][mode_name]
        end
        csv << row
      end
    end

    def payment_mode_particular_wise_csv report_data
      FasterCSV.generate do |csv|
        row = [I18n.t('sl_no'), I18n.t('finance_reports.particular_head'), I18n.t('total')]
        report_data[:payment_modes_list].each do |mode_name|
          row << mode_name
        end
        csv << row
        csv << ""
        report_data[:master_particulars].each_with_index do |master_particular, i|
          row = [(i+1), master_particular.name, report_data[:payment_modes_data][master_particular.id][:total]]
          report_data[:payment_modes_list].each do |mode_name|
            v = report_data[:payment_modes_data][master_particular.id][:mode_totals][mode_name]
            row << (v.is_a?(Hash) ? '-' : FedenaPrecision.set_and_modify_precision(v))
          end
          csv << row
        end
        row = [I18n.t('grand_total'),'', report_data[:grand_totals][:total]]
        report_data[:payment_modes_list].each do |mode_name|
          row << report_data[:grand_totals][:mode_totals][mode_name]
        end
        csv << row
      end
    end


    private
    def value_or_hash value
      value.is_a?(Hash) ? '-' : FedenaPrecision.set_and_modify_precision(value)
      default_value(value)
    end

    def default_value value, default_value = '-'
      return value unless value.is_a? String
      value.empty? ? (default_value || '-') : value
    end
  end
end
