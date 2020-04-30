class MasterParticularReport < ActiveRecord::Base
  require 'locking_pessimistic_extension'
  # enables block with Intention / Exclusive Lock on object
  include Locking::PessimisticExtension

  belongs_to :student
  belongs_to :batch
  belongs_to :master_fee_particular
  belongs_to :fee_account
  belongs_to :collection, :polymorphic => true

  cattr_reader :per_page
  @@per_page = 20

  class << self
    ## TO DO :: add filters to return archived students data also
    ## TO DO :: check for report order (all)
    def search args
      return false, 'invalid_method_called' unless respond_to?(args[:search_method])

      send args[:search_method], args.except(:search_method)
    end

    def payment_mode_summary_transaction args
      validation = validate_date_range args
      return validation if validation.is_a?(Array)

      send "payment_mode_#{args[:mode]}_summary", args
    end
    
    def build_search_keys search_params
      conditions = ["batch_id in (?) and date between ? and ?" , 
        search_params[:batch_id], search_params[:start_date], search_params[:end_date]]
     
      fee_account_ids = search_params[:fee_account_ids]
      conditions = fee_account_search_keys(conditions, fee_account_ids) if fee_account_ids.present?
      search_keys = {:conditions => conditions}.merge!({:order => "date", :select => "DISTINCT date"})
      search_keys
    end
    
    def fee_account_search_keys conditions, fee_account_ids, table='master_particular_reports'
      if fee_account_ids.include? "0"
        conditions[0] += " AND (#{table}.fee_account_id in (?) OR #{table}.fee_account_id is null)"
      else
        conditions[0] += " AND #{table}.fee_account_id in (?)"
      end
      conditions << fee_account_ids.map(&:to_i)
      conditions
    end
    
    def particular_wise_daily_transaction args
      validation = validate_date_range args
      return validation if validation.is_a?(Array)
      search_params = build_search_params args
      report = search_params

      search_keys = build_search_keys search_params

      if args[:fetch_all].present?
        search_type = :all
      else
        search_keys.merge!({:page => search_params[:page], :per_page => search_params[:per_page]})
        search_type = :paginate
      end
      report[:dates] = dates = MasterParticularReport.send(search_type, search_keys)

      report[:search_start_date] = search_sdate = dates.map(&:date).try(:first)
      report[:search_end_date] = search_edate = dates.map(&:date).try(:last)
      
      conditions = ["master_particular_reports.batch_id in (?) and date between ? and ?",
        search_params[:batch_id], search_sdate, search_edate]
     
      fee_account_ids = search_params[:fee_account_ids]
      conditions = fee_account_search_keys(conditions, fee_account_ids) if fee_account_ids.present?
      
      data = MasterParticularReport.all(:conditions => conditions,
        :from => "master_particular_reports force index(index_by_batch_id_and_date)",
        :joins => "INNER JOIN master_fee_particulars mfp
                                                    ON mfp.id = master_particular_reports.master_fee_particular_id",
        :select => "mfp.name as particular_name, mfp.id as particular_id,
                                             sum(amount) AS amount, date",
        :group => "date, master_fee_particular_id")

      report[:particulars] = particulars_list = Hash.new
      report[:particulars_data] = particulars_data = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc) }
      report[:grand_totals] = {:total => 0, :particular_totals => Hash.new {|h,k| h[k] = 0} }
      data.group_by(&:date).each_pair do |date, d_data|
        particulars_data[date][:total] = 0
        particulars_data[date][:particular_totals] ||= {}
        d_data.each do |x|
          particulars_data[date][:total] += x.amount
          particulars_data[date][:particular_totals][x.particular_id] = x.amount
          # grand totals
          report[:grand_totals][:total] += x.amount
          report[:grand_totals][:particular_totals][x.particular_id] += x.amount

          next if particulars_list.has_key?(x.particular_id)
          particulars_list[x.particular_id] = x.particular_name
        end
      end
      report
    end

    def permitted_collection_types expected=false
      collection_types = ['FinanceFeeCollection']
      collection_types << 'TransportFeeCollection' if FedenaPlugin.can_access_plugin?('fedena_transport')
      collection_types << 'HostelFeeCollection' if FedenaPlugin.can_access_plugin?('fedena_hostel')
      unless expected
        collection_types << 'InstantFee' if FedenaPlugin.can_access_plugin?('fedena_instant_fee')
      end
      # collection_types << 'RegistrationCourse' if FedenaPlugin.can_access_plugin?('fedena_applicant_registration')
      collection_types
    end

    def joins_for_permitted_collection_types collection_types
      collection_types.inject("") do |join, collection_type|
        join += " LEFT JOIN #{collection_type.tableize}
                         ON #{collection_type.tableize}.id = collection_master_particular_reports.collection_id and
                            '#{collection_type}' = collection_master_particular_reports.collection_type" unless collection_type == 'RegistrationCourse'
        join
      end
    end

    def build_condition_for_expected_mpr collection_types # collection master particular reports
      l = collection_types.length
      i = 1
      if l > 1
        cond = collection_types.inject(" and ") do |cond, collection_type|
          cond += "," unless (i == 1 or i == l)
          if i != l
            cond += "IFNULL("
          else
            cond += ","
          end
          cond += "#{collection_type.tableize}.due_date" if ['FinanceFeeCollection', 'HostelFeeCollection', 'TransportFeeCollection'].include?(collection_type)
          cond += "#{collection_type.tableize}.pay_date" if ['InstantFee'].include?(collection_type)
          i = i.next
          cond
        end
        1.upto(l-1) { cond += ")"}
      else
        cond = " and #{collection_types.first.tableize}.due_date"
      end
      cond
    end

    def fetch_students search_params
      search_klass = "#{search_params[:expected_amount] ? 'collection_' : ''}master_particular_reports"
      search_keys = {:conditions => ["#{search_klass}.batch_id in (?)", search_params[:batch_id]],
        :select => "#{search_klass}.student_id AS id,
                                 TRIM(IF(s.id IS NULL, concat(IFNULL(a_s.first_name,''),' ',
                                                              IFNULL(a_s.middle_name,''),' ',
                                                              IFNULL(a_s.last_name,'')),
                                      concat(IFNULL(s.first_name,''),' ',IFNULL(s.middle_name,''),' ',
                                             IFNULL(s.last_name,'')))) full_name,
                                 IFNULL(s.admission_no, a_s.admission_no) admission_no,
                                 group_concat(DISTINCT #{search_klass}.batch_id) AS batch_ids",
        :joins => "LEFT JOIN students s ON s.id = #{search_klass}.student_id
                                LEFT JOIN archived_students a_s
                                       ON a_s.former_id = #{search_klass}.student_id",
        # :from => "students use index for join (PRIMARY)",
        :order => "full_name", :group => "#{search_klass}.student_id"}

      if search_params[:fetch_all].present?
        search_type = :all
      else
        search_keys.merge!({:page => search_params[:page], :per_page => search_params[:per_page]})
        search_type = :paginate
      end

      # report[:students] = students = Student.send(search_type, search_keys)
      collection_types = permitted_collection_types

      if search_params[:expected_amount]
        search_keys[:joins] += joins_for_permitted_collection_types(collection_types)
        search_keys[:conditions][0] += "#{build_condition_for_expected_mpr(collection_types)} between ? and ? and #{search_klass}.collection_type IN (?)"
        search_keys[:conditions] += [search_params[:start_date], search_params[:end_date], collection_types]
        # puts search_keys.inspect
        CollectionMasterParticularReport.send(search_type, search_keys)
      else
        search_keys[:conditions][0] += "  and #{search_klass}.date between ? and ? and #{search_klass}.collection_type IN (?)"
        search_keys[:conditions] += [search_params[:start_date], search_params[:end_date], collection_types]
        # puts search_keys.inspect
        MasterParticularReport.send(search_type, search_keys)
      end
    end

    def fetch_student_fee_data search_params, student_ids, expected = false, expected_report = false
      if expected # expected information
        fy_id = search_params[:financial_year_id] == '0' ? nil : search_params[:financial_year_id]
        search_keys = {:conditions => ["collection_master_particular_reports.batch_id in (?) and
                               collection_master_particular_reports.financial_year_id #{fy_id.present? ? '=' : 'IS'} ? and collection_master_particular_reports.student_id IN (?)", search_params[:batch_id],
            fy_id, student_ids],
          :joins => "INNER JOIN master_fee_particulars mfp
                                                  ON mfp.id = collection_master_particular_reports.master_fee_particular_id",
          :select => "mfp.name as particular_name, mfp.id as particular_id,
                                           sum(collection_master_particular_reports.amount) AS amount, collection_master_particular_reports.student_id",
          :group => "collection_master_particular_reports.student_id, collection_master_particular_reports.master_fee_particular_id"
        }
        collection_types = permitted_collection_types(true)
        search_keys[:joins] += joins_for_report(collection_types,'collection_master_particular_reports')
        search_keys[:conditions][0] += conditions_for_report(collection_types,search_params[:start_date], search_params[:end_date], search_params[:fee_account_ids])
        CollectionMasterParticularReport.all(search_keys)
        # expected_data = report[:expected_data].group_by(&:student_id)
      else # paid information
        # puts "fetching MPR"
        expection_collection_type = expected_report ? "InstantFee" : ""
        conditions = ["master_particular_reports.batch_id in (?) and
            master_particular_reports.date between ? and ? and master_particular_reports.student_id IN (?) and master_particular_reports.collection_type <> ?", search_params[:batch_id], search_params[:start_date],
          search_params[:end_date], student_ids, expection_collection_type]
       
        fee_account_ids = search_params[:fee_account_ids]
        conditions = fee_account_search_keys(conditions, fee_account_ids) if fee_account_ids.present?
        
        search_keys = {:conditions => conditions,
          :select => "mfp.name as particular_name, mfp.id as particular_id, sum(amount) AS amount, student_id,
                                                                      mfp.particular_type AS mfp_type",
          :joins => "INNER JOIN master_fee_particulars mfp ON mfp.id = master_particular_reports.master_fee_particular_id",
          :group => "master_particular_reports.student_id, master_particular_reports.master_fee_particular_id"
        }
        if expected_report
          collection_types = permitted_collection_types(true)
          search_keys[:joins] += joins_for_report(collection_types,'master_particular_reports')
          search_keys[:conditions][0] += conditions_for_report(collection_types,search_params[:start_date], search_params[:end_date])
        end
        MasterParticularReport.all(search_keys)

      end
      
    end
    
    def conditions_for_report collection_types,start_date,end_date, account_ids=[]
      conditions = ""
      count = collection_types.count
      collection_types.each_with_index do |c_type, indx|
        conditions += " AND ( " if indx == 0
        conditions += fee_account_search_keys_for_collection(account_ids, c_type) if account_ids.present? #fee account comdition
        conditions += "#{c_type.underscore}s.due_date between DATE('#{start_date}') and DATE('#{end_date}'))" if count == (indx+1)
        conditions += "#{c_type.underscore}s.due_date between DATE('#{start_date}') and DATE('#{end_date}') OR " unless count == (indx+1)
      end
      conditions
    end
    
    def fee_account_search_keys_for_collection fee_account_ids, c_type
      if fee_account_ids.include? "0"
        conditions = "(#{c_type.underscore}s.fee_account_id in (#{fee_account_ids.join(',')}) OR #{c_type.underscore}s.fee_account_id is null) AND "
      else
        conditions = "#{c_type.underscore}s.fee_account_id in (#{fee_account_ids.join(',')}) AND "
      end
      conditions
    end
    
    def joins_for_report collection_types, type
      joins = ""
      collection_types.each do |c_type|
        joins += " LEFT JOIN #{c_type.underscore}s ON #{c_type.underscore}s.id = #{type}.collection_id 
and '#{c_type}' = #{type}.collection_type "
      end
      joins
    end

    def particular_wise_student_transaction args
      validation = validate_date_range args
      return validation if validation.is_a?(Array)
      search_params = build_search_params args
      report = search_params
      report[:students] = students = fetch_students(search_params)
      student_ids = students.map(&:id)
      report[:batches] = Batch.find(students.map(&:batch_ids).join(",").split(",").uniq, :include => :course).group_by {|x| x.id }
      report[:data] = data = fetch_student_fee_data(search_params, student_ids, false, search_params[:expected_amount])
      if search_params[:expected_amount]
        report[:expected_data] = expected_data = fetch_student_fee_data(search_params, student_ids, true) if search_params[:expected_amount]
        # data_gp = data.map(&:student_id)
        data_gp = data.group_by(&:student_id)
      end

      report[:particulars] = particulars_list = Hash.new
      report[:students_data] = students_data = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc) }
      # student_ids = []
      report[:grand_totals] = {:total => 0, :particular_totals => Hash.new {|h,k| h[k] = 0} }
      report[:grand_totals][:expected_particular_totals] = Hash.new {|h,k| h[k] = 0} if search_params[:expected_amount]

      (search_params[:expected_amount] ? expected_data : data).group_by(&:student_id).each_pair do |student_id, student_data|
        student_id = student_id.to_i
        # student_ids << student_id
        students_data[student_id][:total] = 0
        # students_data[student_id][:particular_totals] ||= {}
        # students_data[student_id][:expected_particular_totals] ||= {}
        # students_data[student_id][:balance_particular_totals] ||= {}
        student_data.each do |x|
          students_data[student_id][:particular_totals][x.particular_id] = search_params[:expected_amount] ?
            (data_gp[student_id].select {|d| d.particular_id.to_i == x.particular_id.to_i }.try(:first).try(:amount) rescue 0) : x.amount
          students_data[student_id][:total] += search_params[:expected_amount] ?
            students_data[student_id][:particular_totals][x.particular_id].to_f : x.amount
          # grand totals
          report[:grand_totals][:total] += search_params[:expected_amount] ?
            students_data[student_id][:particular_totals][x.particular_id].to_f : x.amount
          report[:grand_totals][:particular_totals][x.particular_id] += search_params[:expected_amount] ?
            students_data[student_id][:particular_totals][x.particular_id].to_f : x.amount

          if search_params[:expected_amount]
            # particulars data
            # puts  expected_data[student_id].inspect
            students_data[student_id][:expected_particular_totals][x.particular_id] = x.amount
            students_data[student_id][:balance_particular_totals][x.particular_id] = x.amount.to_f - students_data[student_id][:particular_totals][x.particular_id].to_f

            report[:grand_totals][:expected_particular_totals][x.particular_id] += x.amount
            # grand totals data

          end

          next if particulars_list.has_key?(x.particular_id)
          particulars_list[x.particular_id] = x.particular_name
        end
      end

      ## fine data
      if search_params[:expected_amount]
        paid_fine_data = data.select {|x| x.mfp_type == 'Fine'}
        if paid_fine_data.present?
          report[:fine_data] = 1
          students_with_fine = paid_fine_data.group_by(&:student_id) #.keys

          students_with_fine.each_pair do |student_id, student_data|
            student_data.each do |x|
              students_data[student_id][:total] = 0 if students_data[student_id][:total].is_a?(Hash)
              students_data[student_id][:particular_totals][x.particular_id] = 0 if students_data[student_id][:particular_totals][x.particular_id].is_a?(Hash)
              students_data[student_id][:particular_totals][x.particular_id] += x.amount
              students_data[student_id][:total] += x.amount
              # grand totals
              report[:grand_totals][:total] += x.amount
              report[:grand_totals][:particular_totals][x.particular_id] += x.amount

              # if search_params[:expected_amount]
              #   # particulars data
              #   # puts  expected_data[student_id].inspect
              #   students_data[student_id][:expected_particular_totals][x.particular_id] = x.amount
              #   students_data[student_id][:balance_particular_totals][x.particular_id] = x.amount.to_f - students_data[student_id][:particular_totals][x.particular_id].to_f
              #
              #   report[:grand_totals][:expected_particular_totals][x.particular_id] += x.amount
              #   # grand totals data
              #
              # end

              next if particulars_list.has_key?(x.particular_id)
              particulars_list[x.particular_id] = x.particular_name
            end
          end
        end
      end
      # puts report[:particulars].inspect
      report
    end

    # NOT in use
    def particular_wise_student_transaction_old args
      validation = validate_date_range args
      return validation if validation.is_a?(Array)
      search_params = build_search_params args
      report = search_params
      search_klass = "#{search_params[:expected_amount] ? 'collection_' : ''}master_particular_reports"
      # puts search_klass
      search_keys = {:conditions => ["#{search_klass}.batch_id in (?)", search_params[:batch_id]],
        :select => "#{search_klass}.student_id AS id,
                                 TRIM(IF(s.id IS NULL, concat(IFNULL(a_s.first_name,''),' ',
                                                              IFNULL(a_s.middle_name,''),' ',
                                                              IFNULL(a_s.last_name,'')),
                                      concat(IFNULL(s.first_name,''),' ',IFNULL(s.middle_name,''),' ',
                                             IFNULL(s.last_name,'')))) full_name,
                                 IFNULL(s.admission_no, a_s.admission_no) admission_no,
                                 group_concat(DISTINCT #{search_klass}.batch_id) AS batch_ids",
        :joins => "LEFT JOIN students s ON s.id = #{search_klass}.student_id
                                LEFT JOIN archived_students a_s
                                       ON a_s.former_id = #{search_klass}.student_id",
        # :from => "students use index for join (PRIMARY)",
        :order => "full_name", :group => "#{search_klass}.student_id"}

      if args[:fetch_all].present?
        search_type = :all
      else
        search_keys.merge!({:page => search_params[:page], :per_page => search_params[:per_page]})
        search_type = :paginate
      end
      # report[:students] = students = Student.send(search_type, search_keys)
      collection_types = permitted_collection_types

      if search_params[:expected_amount]
        search_keys[:joins] += joins_for_permitted_collection_types(collection_types)
        search_keys[:conditions][0] += "#{build_condition_for_expected_mpr(collection_types)} between ? and ? and #{search_klass}.collection_type IN (?)"
        search_keys[:conditions] += [search_params[:start_date], search_params[:end_date], collection_types]
        # puts search_keys.inspect
        report[:students] = students = CollectionMasterParticularReport.send(search_type, search_keys)
        student_ids = students.map(&:id)
        report[:expected_amount] = true
        fy_id = search_params[:financial_year_id] == '0' ? nil : search_params[:financial_year_id]
        report[:expected_data] = CollectionMasterParticularReport.all(:conditions => ["collection_master_particular_reports.batch_id in (?) and
                               financial_year_id #{fy_id.present? ? '=' : 'IS'} ? and student_id IN (?)", search_params[:batch_id],
            fy_id, student_ids],
          :joins => "INNER JOIN master_fee_particulars mfp
                                                  ON mfp.id = collection_master_particular_reports.master_fee_particular_id",
          :select => "mfp.name as particular_name, mfp.id as particular_id,
                                           sum(amount) AS amount, student_id",
          :group => "student_id, master_fee_particular_id")
        expected_data = report[:expected_data].group_by(&:student_id)
      else
        search_keys[:conditions][0] += "  and #{search_klass}.date between ? and ? and #{search_klass}.collection_type IN (?)"
        search_keys[:conditions] += [search_params[:start_date], search_params[:end_date], collection_types]
        # puts search_keys.inspect
        report[:students] = students = MasterParticularReport.send(search_type, search_keys)
        student_ids = students.map(&:id)
      end

      session_limit_row_sql="SET SESSION group_concat_max_len = 1000000;"
      report[:batches] = Batch.find(students.map(&:batch_ids).join(",").split(",").uniq, :include => :course).group_by {|x| x.id }

      report[:data] = data = MasterParticularReport.all(:conditions => ["master_particular_reports.batch_id in (?) and
            date between ? and ? and student_id IN (?)", search_params[:batch_id],
          search_params[:start_date], search_params[:end_date], student_ids],
        :joins => "INNER JOIN master_fee_particulars mfp
        ON mfp.id = master_particular_reports.master_fee_particular_id",
        :select => "mfp.name as particular_name, mfp.id as particular_id,
                                                                                                             sum(amount) AS amount, student_id",
        :group => "student_id, master_fee_particular_id")

      report[:particulars] = particulars_list = Hash.new
      report[:students_data] = students_data = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc) }
      student_ids = []
      report[:grand_totals] = {:total => 0, :particular_totals => Hash.new {|h,k| h[k] = 0} }
      (search_params[:expected_amount] ? expected_data : data.group_by(&:student_id)).each_pair do |student_id, student_data|
        student_id = student_id.to_i
        student_ids << student_id
        students_data[student_id][:total] = 0
        students_data[student_id][:particular_totals] ||= {}
        students_data[student_id][:expected_particular_totals] ||= {}
        students_data[student_id][:balance_particular_totals] ||= {}
        student_data.each do |x|
          students_data[student_id][:total] += x.amount
          students_data[student_id][:particular_totals][x.particular_id] = x.amount
          # grand totals
          report[:grand_totals][:total] += x.amount
          report[:grand_totals][:particular_totals][x.particular_id] += x.amount

          if search_params[:expected_amount]
            # particulars data
            # puts  expected_data[student_id].inspect
            students_data[student_id][:expected_particular_totals][x.particular_id] = expected_data[student_id].select {|x| x.particular_id == x.particular_id}.try(:first).try(:amount)
            # grand totals data

          end

          next if particulars_list.has_key?(x.particular_id)
          particulars_list[x.particular_id] = x.particular_name
        end
      end
      report
    end

    def payment_mode_batch_wise_summary args
      search_params = build_search_params args
      report = search_params
      batch_search_conditions = ["batch_id in (?) and date between ? and ?",
        search_params[:batch_id], search_params[:start_date], search_params[:end_date]]
      fee_account_ids = search_params[:fee_account_ids]
      batch_search_conditions = fee_account_search_keys(batch_search_conditions, fee_account_ids, 'mpr') if fee_account_ids.present?
      search_keys = {:conditions => batch_search_conditions,
        :joins => "INNER JOIN master_particular_reports mpr ON mpr.batch_id = batches.id",
        :order => "name", :select => "Distinct batches.*" }
      if args[:fetch_all].present?
        search_type = :all
      else
        search_keys.merge!({:page => search_params[:page], :per_page => search_params[:per_page]})
        search_type = :paginate
      end

      report[:batches] = Batch.send(search_type, search_keys)

      batch_ids = report[:batches].map(&:id)
      conditions = ["master_particular_reports.batch_id in (?) and date between ? and ?",
        batch_ids, search_params[:start_date], search_params[:end_date]]
      fee_account_ids = search_params[:fee_account_ids]
      conditions = fee_account_search_keys(conditions, fee_account_ids) if fee_account_ids.present?
      data = MasterParticularReport.all(:conditions => conditions,
        # :from => "force index(index_by_batch_id_and_date)",
        :select => "mode_of_payment, batch_id, fee_account_id, sum(amount) AS amount",
        :group => "batch_id, mode_of_payment")

      report[:payment_modes_list] = payment_modes_list = Array.new
      report[:payment_modes_data] = payment_modes_data = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc) }
      report[:grand_totals] = {:total => 0, :mode_totals => Hash.new {|h,k| h[k] = 0} }
      data.group_by(&:batch_id).each_pair do |batch_id, mode_data|
        batch_id = batch_id.to_i
        payment_modes_data[batch_id][:total] = 0

        mode_data.each do |x|
          payment_modes_data[batch_id][:total] += x.amount
          payment_modes_data[batch_id][:mode_totals][x.mode_of_payment] = x.amount
          # grand totals
          report[:grand_totals][:total] += x.amount
          report[:grand_totals][:mode_totals][x.mode_of_payment] += x.amount

          next if payment_modes_list.include?(x.mode_of_payment)
          payment_modes_list << x.mode_of_payment
        end
      end
      report
    end

    def payment_mode_particular_wise_summary args
      search_params = build_search_params args
      report = search_params
      particular_conditions = ["batch_id in (?) and date between ? and ?",
        search_params[:batch_id], search_params[:start_date], search_params[:end_date]]
      fee_account_ids = search_params[:fee_account_ids]
      particular_conditions = fee_account_search_keys(particular_conditions, fee_account_ids, 'mpr') if fee_account_ids.present?
      search_keys = {:conditions => particular_conditions,
        :joins => "INNER JOIN master_particular_reports mpr
                                        ON mpr.master_fee_particular_id = master_fee_particulars.id",
        :order => "name", :select => "Distinct master_fee_particulars.*"}
      if args[:fetch_all].present?
        search_type = :all
      else
        search_keys.merge!({:page => search_params[:page], :per_page => search_params[:per_page]})
        search_type = :paginate
      end

      report[:master_particulars] = MasterFeeParticular.send(search_type, search_keys)
      
      conditions = ["master_particular_reports.batch_id in (?) and date between ? and ?",
          search_params[:batch_id], search_params[:start_date], search_params[:end_date]]
      fee_account_ids = search_params[:fee_account_ids]
      conditions = fee_account_search_keys(conditions, fee_account_ids) if fee_account_ids.present?
      data = MasterParticularReport.all(:conditions => conditions,
        # :from => "force index(index_by_batch_id_and_date)",
        :select => "master_fee_particular_id, mode_of_payment, sum(amount) AS amount",
        :group => "master_fee_particular_id, mode_of_payment")

      report[:payment_modes_list] = payment_modes_list = Array.new
      report[:payment_modes_data] = payment_modes_data = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc) }
      report[:grand_totals] = {:total => 0, :mode_totals => Hash.new {|h,k| h[k] = 0} }
      data.group_by(&:master_fee_particular_id).each_pair do |master_particular_id, mode_data|
        master_particular_id = master_particular_id.to_i
        payment_modes_data[master_particular_id][:total] = 0

        mode_data.each do |x|
          payment_modes_data[master_particular_id][:total] += x.amount
          payment_modes_data[master_particular_id][:mode_totals][x.mode_of_payment] = x.amount
          # grand totals
          report[:grand_totals][:total] += x.amount
          report[:grand_totals][:mode_totals][x.mode_of_payment] += x.amount

          next if payment_modes_list.include?(x.mode_of_payment)
          payment_modes_list << x.mode_of_payment
        end
      end
      report
    end
    
    def fee_account_names acc_ids
      fee_accounts = FeeAccount.find_all_by_id(acc_ids).map(&:name)
      fee_accounts << "Default" if acc_ids.include? '0'
      fee_accounts = fee_accounts.join(', ')
    end

    def build_search_params args
      search_params = Hash.new

      batches = fetch_batches args[:course_id], args[:batch_id]

      search_params[:batch_id] = batches.map(&:id)
      search_params[:start_date] = args[:start_date]
      search_params[:end_date] = args[:end_date]
      search_params[:page] = args[:page] || 1

      search_params[:per_page] = args[:per_page] || per_page
      search_params[:course_names] = args[:course_id] == 'all' ? t('all') : Course.find_all_by_id(args[:course_id]).map(&:course_name).join(',')
      search_params[:batch_names] = args[:course_id] == 'all' ? t('all') : args[:batch_id] == 'all' ? t('all') : batches.map(&:full_name).join(',')
      search_params[:financial_year_id] = args[:financial_year_id]
      search_params[:fee_account_ids] = args[:fee_account_ids].present? ? args[:fee_account_ids] : []
      search_params[:fee_account_names] = args[:fee_account_ids].present? ? fee_account_names(args[:fee_account_ids]) : ""
      fy_id = (args[:financial_year_id].to_i == 0 ? nil : args[:financial_year_id])
      search_params[:financial_year_name] = FinancialYear.fetch_name(fy_id)
      # to decide if need to paginate or not
      search_params[:fetch_all] = args[:fetch_all]
      # used only for student transaction report
      search_params[:expected_amount] = (args[:expected_amount] == 1)
      # puts search_params.inspect
      search_params
    end

    def validate_date_range args
      start_date = args[:start_date]
      end_date = args[:end_date]
      return false, 'date_range_missing' unless start_date.present? and end_date.present?
      return false, 'start_date_must_be_smaller' if start_date > end_date
      return true
    end

    def fetch_batches course_id, batch_ids
      # return batch_ids if batch_ids.present?
      if course_id == 'all'
        Batch.active #.map(&:id)
      elsif batch_ids == 'all'
        Batch.active.all(:conditions => ["course_id = ?", course_id]) #.map(&:id)
      elsif batch_ids.present?
        Batch.active.all(:conditions => ["course_id IN (?) and batches.id IN (?)", course_id, batch_ids]) #.map(&:id)
      elsif course_id.present?
        Batch.active.all(:conditions => ["course_id IN (?)", course_id]) #.map(&:id)
      end
    end

  end
end