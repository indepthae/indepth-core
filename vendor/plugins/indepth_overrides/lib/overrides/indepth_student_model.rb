module IndepthOverrides
  module IndepthStudentModel
  	def self.included (base)
  		base.instance_eval do
        after_update :update_familyid
        attr_accessor :revert_mode
	  		extend ClassMethods
	  	end
  	end
        
    def update_familyid
      siblings = Student.find_all_by_sibling_id(self.sibling_id, :include => :guardians)
      sibling_ids = siblings.collect {|s| s.id if s.familyid != self.familyid }.compact
      sibling_guardians = siblings.collect do |s| 
        s.guardians.collect {|g| g if g.familyid != self.familyid }
      end.flatten.compact      
      Student.update_all("familyid = #{self.familyid}", 
        {:id => sibling_ids}) if sibling_ids.present?
      guardians = Guardian.all(:include => :user,
        :conditions => "familyid <> #{self.familyid} AND ward_id = #{self.sibling_id}")
      guardians.each do |g|
        u = g.user
        next unless u.present?
        u.password = "#{self.familyid}123"
        u.save
      end
      
      
      Guardian.update_all("familyid = #{self.familyid}", 
        "familyid <> #{self.familyid} AND ward_id = #{self.sibling_id}") if guardians.present?
      Guardian.update_all("familyid = #{self.familyid}", 
        {:id => sibling_guardians.map(&:id)}) if sibling_guardians.present?
      
      (guardians + sibling_guardians).compact.uniq.each do |g|
        u = g.user
        next unless u.present?
        u.password = "#{self.familyid}123"
        u.save
      end if sibling_guardians.present? or guardians.present?
      
    end
    
    module ClassMethods
      
      def fetch_single_statement_data family_id
        _data = Hash.new
        op_bal = 0
        
        _data[:students] = Student.active.find_all_by_familyid(family_id,
          :include => [{:batch => [{:fee_collection_batches => :finance_fee_collection },
                :finance_fee_particulars]},{:finance_transactions => 
                [:category, :transaction_receipt]},:instant_fees])        
        
        financial_year_start_date = Configuration.find_by_config_key("FinancialYearStartDate")
        financial_year_end_date = Configuration.find_by_config_key("FinancialYearEndDate")
        
        start_date = financial_year_start_date.config_value.to_date
        end_date = financial_year_end_date.config_value.to_date
        
        _data[:financial_year_start] = start_date.year if start_date.present?
        _data[:financial_year_end] = end_date.year if end_date.present?
        
        #        _data[:transactions] = _data[:students].map do |s| 
        #          s.finance_transactions.all(:include => :transaction_receipt, :joins => :category, 
        #            :conditions => "finance_transaction_categories.is_income = true")
        #        end.flatten.select do |a| 
        #          (a.transaction_date >= financial_year_start_date.config_value.to_date) && 
        #            (a.transaction_date <= financial_year_end_date.config_value.to_date)
        #        end.sort_by{|t| t.transaction_date}
        _data[:total] = 0
        _data[:student_fines] = _student_fines = Hash.new
        
        _data[:transactions] = _data[:students].map do |s| 
          fine_amount = 0
          fts = s.finance_transactions.select do |x| 
            if x.category.is_income == true && x.transaction_date >= start_date && x.transaction_date <= end_date
              fine_amount += (x.description == 'fine_amount_included' ?
                  (x.auto_fine.to_f == 0 ? x.fine_amount.to_f : 
                    x.fine_amount.to_f - x.auto_fine.to_f) : 
                  x.fine_amount.to_f)
              
              x             
            end
          end
          
          if fine_amount > 0
            _student_fines["#{s.id}"] ||= 0
            _student_fines["#{s.id}"] += fine_amount
          end
          
          fts
        end.flatten.sort_by{|t| t.transaction_date }
      
        _data[:total_paid] = _data[:transactions].collect(&:amount).sum.to_f
                
        particular_data = FinanceFee.all(
#          :include => {:finance_fee_discounts => :fee_discount}, 
          :select => "finance_fees.id, s.id AS sid, s.familyid, s.batch_id, 
                      s.first_name, ffc.name as ffc_name, 
                      ffc.due_date as ffc_due_date, ffc.start_date as ffc_start_date, 
                      ffp.id as ffp_id, ffp.amount as ffp_amount, ffp.name as ffp_name, 
                      ffp.finance_fee_category_id as ffp_category_id, 
                      ffp.created_at as ffp_created, fr.is_amount, fr.fine_amount",  
          :joins => "INNER JOIN students s ON s.id = finance_fees.student_id 
                     INNER JOIN finance_fee_collections ffc ON ffc.id = finance_fees.fee_collection_id 
                     INNER JOIN collection_particulars cp  ON cp.finance_fee_collection_id = ffc.id 
                     INNER JOIN finance_fee_particulars ffp  
                             ON ffp.id = cp.finance_fee_particular_id and 
                                ((ffp.receiver_id = s.id and ffp.receiver_type = 'Student') or 
                                 (ffp.receiver_id = s.student_category_id and 
                                  ffp.receiver_type = 'StudentCategory' and 
                                  ffp.batch_id = finance_fees.batch_id) or 
                                 (ffp.receiver_id = finance_fees.batch_id and 
                                  ffp.receiver_type = 'Batch'))
                      LEFT JOIN fines f ON f.id = ffc.fine_id
                      LEFT JOIN fine_rules fr 
                             ON fr.id = (SELECT id 
                                           FROM fine_rules ffr 
                                          WHERE ffr.fine_id=ffc.fine_id AND 
                                                ffr.created_at <= ffc.created_at AND 
                                                ffr.fine_days <= DATEDIFF(
                                                COALESCE(CURDATE()),ffc.due_date) 
                                       ORDER BY ffr.fine_days DESC LIMIT 1)", 
          :conditions => ["s.familyid = ? and ffc.due_date >= ? and 
                           ffc.due_date <= ? ", family_id, start_date.to_date, 
            end_date.to_date], :order => "ffp_created asc")
        #        _data[:data] = particular_discount_data
        _data[:particular_names] = particular_data.map(&:ffp_name).uniq
        _data[:student_particulars] = _student_particulars = Hash.new
        student_particular_ids = Hash.new
        pids = []
        dids = []
        dnames = [] 
        ff_totals = {}
        particulars = {}
        particular_data.group_by(&:sid).each do |sid, p_data|
          student_particular_ids[sid] ||= Hash.new
          
          p_data.group_by {|x| x.id}.each_pair do |ff_id, ff|
            student_particular_ids[sid][ff_id.to_i] ||= Array.new
            pids = []
            dids = []
            amt = 0
            ff.each do |pd|
          
              unless pids.include?(pd.ffp_id)          
                _student_particulars[sid] ||= Hash.new
                pids << pd.ffp_id
                
                _student_particulars[sid][pd.ffp_name] ||= 0
                _data[:total] += pd.ffp_amount.to_f
                particulars[pd.ffp_id] = pd.ffp_amount.to_f
                _student_particulars[sid][pd.ffp_name] += pd.ffp_amount.to_f
                amt += pd.ffp_amount.to_f
              end
              
            end
            
            student_particular_ids[sid][ff_id.to_i] += pids.map(&:to_i)
            
            ff_totals[ff_id] = amt            
            
            # ffds = ff[0].finance_fee_discounts
            #
            # ffds.each do |fd|
            #   _data[:total] -= fd.discount_amount.to_f
            #   amt -= fd.discount_amount.to_f
            #   _student_discounts[sid] ||= Hash.new
            #   fd_name = fd.fee_discount.name
            #   dnames << fd_name unless dnames.include?(fd_name)
            #   _student_discounts[sid][fd_name] ||= 0
            #   _student_discounts[sid][fd_name] += fd.discount_amount.to_f
            # end
            
            if ff[0].fine_amount.to_f > 0
              _student_fines[sid] ||= 0
              _student_fines[sid] += (ff[0].is_amount.to_i == 1 ? ff[0].fine_amount.to_f : (ff[0].fine_amount.to_f * amt * 0.01))
            end            
          end
        end
                
        discount_data = FinanceFee.all(:select => "finance_fees.id AS ff_id, 
                       fd.name AS fd_name, s.id AS sid, fd.id AS fd_id,
                       fd.is_amount AS is_amount, fd.discount AS discount,
                       fd.master_receiver_id AS fd_master_receiver_id, 
                       fd.master_receiver_type AS fd_master_receiver_type,
                       fd.receiver_id AS fd_receiver_id, 
                       fd.receiver_type AS fd_receiver_type",
            :joins => "INNER JOIN students s ON s.id = finance_fees.student_id
                       INNER JOIN finance_fee_collections ffc 
                               ON ffc.id = finance_fees.fee_collection_id
                       INNER JOIN collection_discounts cd 
                               ON cd.finance_fee_collection_id=ffc.id
                       INNER JOIN fee_discounts fd ON fd.id = cd.fee_discount_id",
            :conditions => ["s.familyid = ? AND ffc.due_date BETWEEN ? AND ? AND 
                             fd.batch_id = finance_fees.batch_id AND
                             ((fd.receiver_type ='Batch' AND fd.receiver_id = finance_fees.batch_id) OR
                              (fd.receiver_type='StudentCategory' AND fd.receiver_id = s.student_category_id) OR
                              (fd.receiver_type ='Student' AND fd.receiver_id = s.id))",
                            family_id, start_date.to_date, end_date.to_date])

        _data[:discount_names] = discount_data.map(&:fd_name).uniq
        _data[:student_discounts] = _student_discounts = Hash.new
        
        discount_data.group_by(&:sid).each do |sid, p_data|

          p_data.group_by {|x| x.ff_id}.each_pair do |ff_id, ff|            
            damt = 0
            dids = []
            ff.each do |pd|             
              
              _student_discounts[sid] ||= Hash.new
              
              next if dids.include?(pd.fd_id)
              next if pd.fd_master_receiver_type == 'FinanceFeeParticular' and 
                !student_particular_ids[sid][ff_id.to_i].include?(pd.fd_master_receiver_id.to_i)                
              
              _student_discounts[sid][pd.fd_name] ||= 0
              dids << pd.fd_id
              
              d = pd.is_amount.to_i == 1 ? pd.discount.to_f : (
                ((pd.fd_master_receiver_type == 'FinanceFeeParticular' ?
                      particulars[pd.fd_master_receiver_id].to_f : ff_totals[ff_id.to_i].to_f) * 
                  pd.discount.to_f * 0.01))                 
              
              _student_discounts[sid][pd.fd_name] += d
              damt += d
            end
            _data[:total] -= damt
          end
        end
        
        if FedenaPlugin.can_access_plugin?('fedena_transport')
          _transport_fees = Student.find(:all,
            :select => "students.id, students.familyid, students.batch_id,
                        students.first_name, tf.id as tf_id, tf.bus_fare as tf_fare, 
                        tfc.due_date as tfc_due_date, tfd.id as tfd_id,  
                        tfd.discount as tfd_discount, tfd.is_amount as tfd_is_amount,
                        tfd.name as tfd_name, fr.is_amount, fr.fine_amount",
            :joins => "INNER JOIN transport_fees tf ON tf.receiver_id = students.id
                       INNER JOIN transport_fee_collections tfc 
                               ON tfc.id = tf.transport_fee_collection_id
                        LEFT JOIN transport_fee_discounts tfd 
                               ON tfd.transport_fee_id = tf.id
                        LEFT JOIN fines f ON f.id = tfc.fine_id
                        LEFT JOIN fine_rules fr 
                               ON fr.fine_id = f.id  AND 
                                  fr.id = (SELECT id 
                                             FROM fine_rules ffr 
                                            WHERE ffr.fine_id=tfc.fine_id AND 
                                                  ffr.created_at <= tfc.created_at AND 
                                                  ffr.fine_days <= DATEDIFF(
                                                  COALESCE(CURDATE()),tfc.due_date) 
                                         ORDER BY ffr.fine_days DESC LIMIT 1)",
            :conditions => ["familyid = ? and tfc.due_date >= ? and tfc.due_date <= ? ",
              family_id, start_date.to_date, end_date.to_date])
          
          _tp_name = "Bus Fare"
          
          
          dids = []
          dnames = []
          tamount = 0
          _transport_fees.group_by(&:id).each do |sid, tfd|
            amt = 0
            tfd.each do |tf|
              _student_particulars["#{sid}"] ||= Hash.new
              fare = tf.tf_fare.to_f
              tamount += fare
              amt += fare
              _student_particulars["#{sid}"][_tp_name] ||= 0
              
              _data[:total] += fare
              _student_particulars["#{sid}"][_tp_name] += fare
              
              unless dids.include?(tf.tfd_id)
                dnames << tf.tfd_name
                _student_discounts["#{sid}"] ||= Hash.new
                dids << tf.tfd_id
                dmt = tf.tfd_is_amount ? tf.tfd_discount.to_f : (tf.tfd_discount.to_f * fare * 0.01)
                amt -= dmt
                _data[:total] -= dmt
                _student_discounts["#{sid}"][tf.tfd_name] ||= 0
                _student_discounts["#{sid}"][tf.tfd_name] += dmt
              end              
            end
            
            if tfd[0].fine_amount.to_f > 0
              _student_fines["#{sid}"] ||= 0
              _student_fines["#{sid}"] += (tfd[0].is_amount.to_i == 1 ? tfd[0].fine_amount.to_f :
                  (tfd[0].fine_amount.to_f * amt * 0.01))              
            end
          end
          
          _data[:particular_names] << _tp_name if tamount > 0

          _data[:discount_names] += dnames.uniq
          
          # fetch fees for opening journal
          
          new_fee_paid_advance = FinanceTransaction.all(:select => "amount",
            :joins => "INNER JOIN students s
                               ON s.id = finance_transactions.payee_id
                       INNER JOIN transport_fees ff 
                               ON ff.id = finance_transactions.finance_id AND 
                                  finance_transactions.finance_type = 'TransportFee'
                       INNER JOIN transport_fee_collections ffc 
                               ON ffc.id = ff.transport_fee_collection_id",
            :conditions => ["s.familyid = ? AND finance_transactions.transaction_date < ? AND 
                             ffc.due_date > ?", family_id, start_date, start_date]
          )
        
          op_bal += new_fee_paid_advance.map(&:amount).sum.to_f
          
          old_t_fees = TransportFee.all(
            :select => "transport_fees.balance, transport_fees.is_paid as is_paid, 
                        transport_fees.balance balance, transport_fees.id as id,
                        (SELECT IFNULL(SUM(finance_transactions.amount - finance_transactions.fine_amount), 0)
                           FROM finance_transactions
                          WHERE finance_transactions.finance_id=transport_fees.id AND
                                finance_transactions.finance_type='TransportFee' AND
                                tfc.due_date < '#{start_date}' AND
                                finance_transactions.transaction_date 
                                BETWEEN '#{start_date}' AND '#{end_date}'
                         ) AS current_paid_amount,
                        (transport_fees.bus_fare - 
                         IFNULL((SELECT SUM(IF(is_amount, discount,
                                               (discount * transport_fees.bus_fare * 0.01))) AS discount 
                                   FROM transport_fee_discounts 
                                  WHERE transport_fee_discounts.transport_fee_id = transport_fees.id 
                               GROUP BY transport_fee_discounts.transport_fee_id),0)) 
                        as actual_amount, fr.fine_amount, fr.is_amount",
            :conditions => ["s.familyid = ? AND tfc.due_date < ? AND 
                             is_paid = false", family_id, start_date],
            :joins => "INNER JOIN students s 
                               ON s.id = transport_fees.receiver_id AND 
                                  transport_fees.receiver_type = 'Student'
                       INNER JOIN transport_fee_collections tfc 
                               ON tfc.id = transport_fees.transport_fee_collection_id
                        LEFT JOIN fines f ON f.id = tfc.fine_id
                        LEFT JOIN fine_rules fr 
                               ON fr.fine_id = f.id  AND 
                                  fr.id = (SELECT id 
                                             FROM fine_rules ffr 
                                            WHERE ffr.fine_id=tfc.fine_id AND 
                                                  ffr.created_at <= tfc.created_at AND 
                                                  ffr.fine_days <= DATEDIFF(
                                                  COALESCE(CURDATE()),tfc.due_date) 
                                         ORDER BY ffr.fine_days DESC LIMIT 1)")
          
          old_t_fees.map do |f|
            op_bal -= f.balance.to_f
            op_bal -= f.current_paid_amount.to_f
            if f.fine_amount.present?
              op_bal -= (f.is_amount ? f.fine_amount.to_f : (f.actual_amount.to_f * f.fine_amount.to_f * 0.01))
            end
          end
        end
        
        if FedenaPlugin.can_access_plugin?('fedena_hostel')
          _hf_fees  = Student.all(
            :select => "students.id, students.familyid, students.batch_id,
                        students.first_name, hf.id as hf_id, 
                        hfc.due_date as hfc_due_date, hf.rent as hf_rent",
            :joins => "INNER JOIN hostel_fees hf ON hf.student_id = students.id
                       INNER JOIN hostel_fee_collections hfc 
                               ON hfc.id = hf.hostel_fee_collection_id",
            :conditions => ["familyid = ? and hfc.due_date >= ? and 
                             hfc.due_date <= ? ", family_id, 
              start_date.to_date, end_date.to_date]) 
                         
          _hf_name = "Room Rent"
                              
          dids = []
          dnames = []
          hamount = 0
          
          _hf_fees.group_by(&:id).each do |sid, hfd|
            hfd.each do |hf|              
              _student_particulars["#{sid}"] ||= Hash.new
              rent = hf.hf_rent.to_f
              hamount += rent
              
              _data[:total] += rent
              _student_particulars["#{sid}"][_hf_name] ||= 0
              _student_particulars["#{sid}"][_hf_name] += rent
            end
          end 
          
          _data[:particular_names] << _hf_name if hamount > 0
          # fetch fees for opening journal
          new_fee_paid_advance = FinanceTransaction.all(:select => "amount",
            :joins => "INNER JOIN students s
                             ON s.id = finance_transactions.payee_id
                     INNER JOIN hostel_fees ff 
                             ON ff.id = finance_transactions.finance_id AND 
                                finance_transactions.finance_type = 'HostelFee'
                     INNER JOIN hostel_fee_collections ffc 
                             ON ffc.id = ff.hostel_fee_collection_id",
            :conditions => ["s.familyid = ? AND finance_transactions.transaction_date < ? AND 
                             ffc.due_date > ?", family_id, start_date, start_date]
          )
        
          op_bal += new_fee_paid_advance.map(&:amount).sum.to_f
          
          old_h_fees = HostelFee.all(:all, 
            :select => "hostel_fees.balance,
                        (SELECT IFNULL(SUM(finance_transactions.amount - finance_transactions.fine_amount), 0)
                           FROM finance_transactions
                          WHERE finance_transactions.finance_id=hostel_fees.id AND
                                finance_transactions.finance_type='HostelFee' AND
                                hfc.due_date < '#{start_date}' AND
                                finance_transactions.transaction_date 
                                BETWEEN '#{start_date}' AND '#{end_date}'
                         ) AS current_paid_amount",
            :conditions => ["s.familyid = ? AND hfc.due_date < ? AND 
                             balance > 0 AND hostel_fees.is_active = true", 
              family_id, start_date],
            :joins => "INNER JOIN students s 
                               ON s.id = hostel_fees.student_id
                       INNER JOIN hostel_fee_collections hfc 
                               ON hfc.id = hostel_fees.hostel_fee_collection_id")
          
          old_h_fees.map do |f|
            op_bal -= f.balance.to_f
            op_bal -= f.current_paid_amount.to_f
          end
        end
      
        if FedenaPlugin.can_access_plugin?('fedena_instant_fee') 
          # @current_instant_fees_details = @students.map{|s| @student_instant_fees[s.id] = s.instant_fees.select{|a| (a.pay_date >= @financial_year_start_date.config_value.to_date) && ((a.pay_date <= @financial_year_end_date.config_value.to_date))}.flatten.map{|b| b.instant_fee_details}.flatten.uniq}
          _instant_fees_details = Student.find(:all,
            :select => "students.id, students.familyid, students.batch_id,
                        students.first_name, inf.id as inf_id, 
                        infd.amount as inf_amount, 
                        IFNULL(infd.amount - infd.net_amount,0) as discount, 
                        IFNULL(infp.name, infd.custom_particular) as infp_name",
            :joins => "INNER JOIN instant_fees inf ON inf.payee_id = students.id
                       INNER JOIN instant_fee_details infd 
                               ON infd.instant_fee_id = inf.id
                        LEFT JOIN instant_fee_particulars infp 
                               ON infp.id = infd.instant_fee_particular_id",
            :conditions => ["familyid = ? and inf.pay_date >= ? and 
                             inf.pay_date <= ? ", family_id, start_date.to_date, 
              end_date.to_date])
          
          ifd_name = "Instant Discount"
          if_ps = []
          total_discount = 0
          _instant_fees_details.group_by(&:id).each do |sid, ifd|
            
            ifd.each do |f|
              _student_particulars["#{sid}"] ||= Hash.new
              if_ps << f.infp_name
              _student_particulars["#{sid}"][f.infp_name] ||= 0
              _student_particulars["#{sid}"][f.infp_name] += f.inf_amount.to_f
              _data[:total] += f.inf_amount.to_f
              discount = f.discount.to_f
              if discount > 0
                _data[:total] -= discount
                total_discount += discount
                _student_discounts["#{sid}"] ||= Hash.new
                _student_discounts["#{sid}"][ifd_name] ||= 0
                _student_discounts["#{sid}"][ifd_name] += discount
              end
            end
          end
          
          _data[:particular_names] += if_ps.uniq.compact
          
          _data[:discount_names] << ifd_name if total_discount > 0
        end
        
        _data[:discount_names] = _data[:discount_names].uniq.compact
        _data[:particular_names] = _data[:particular_names].uniq.compact
            
                
        # to get core opening journal
        #        students_previous_batch = [] # _data[:students].map{|a| a.previous_batch}.compact
        new_fee_paid_advance = FinanceTransaction.all(:select => "amount",
          :joins => "INNER JOIN students s
                             ON s.id = finance_transactions.payee_id
                     INNER JOIN finance_fees ff 
                             ON ff.id = finance_transactions.finance_id AND 
                                finance_transactions.finance_type = 'FinanceFee'
                     INNER JOIN finance_fee_collections ffc 
                             ON ffc.id = ff.fee_collection_id",
          :conditions => ["s.familyid = ? AND finance_transactions.transaction_date < ? AND 
                           ffc.due_date > ?", family_id, start_date, start_date]
        )
        
        op_bal += new_fee_paid_advance.map(&:amount).sum.to_f
        
        old_fees = FinanceFee.all(:select => "finance_fees.id, balance, fr.is_amount, 
                              fr.fine_amount, s.id AS sid, (IFNULL((particular_total - discount_amount),
                              finance_fees.balance +
                              (SELECT IFNULL(SUM(finance_transactions.amount - finance_transactions.fine_amount), 0)
                                 FROM finance_transactions
                                WHERE finance_transactions.finance_id=finance_fees.id AND
                                      finance_transactions.finance_type='FinanceFee') -
                              IF(finance_fees.tax_enabled,finance_fees.tax_amount,0)
                              )) AS actual_amount,
                              (SELECT IFNULL(SUM(finance_transactions.amount - finance_transactions.fine_amount), 0)
                                 FROM finance_transactions
                                WHERE finance_transactions.finance_id=finance_fees.id AND
                                      finance_transactions.finance_type='FinanceFee' AND
                                      ffc.due_date < '#{start_date}' AND
                                      finance_transactions.transaction_date BETWEEN '#{start_date}' AND '#{end_date}'
                              ) AS current_paid",
          :conditions => ["s.familyid = ? AND ffc.due_date < ? AND 
                           finance_fees.is_paid = false", family_id, start_date],
          :joins => "INNER JOIN students s ON s.id = finance_fees.student_id
                     INNER JOIN finance_fee_collections ffc ON ffc.id = finance_fees.fee_collection_id
                      LEFT JOIN fines f ON f.id = ffc.fine_id
                      LEFT JOIN fine_rules fr 
                             ON fr.fine_id = f.id AND
                                fr.id=(SELECT id 
                                         FROM fine_rules ffr 
                                        WHERE ffr.fine_id = ffc.fine_id AND 
                                              ffr.created_at <= ffc.created_at AND 
                                              ffr.fine_days <= DATEDIFF(
                                              COALESCE(CURDATE()),ffc.due_date) 
                                     ORDER BY ffr.fine_days DESC LIMIT 1)")
        
                
        old_fees.map do |f|
          op_bal -= f.balance.to_f          
          op_bal -= f.current_paid.to_f
          if f.fine_amount.present?
            op_bal -= (f.is_amount ? f.fine_amount.to_f : (f.actual_amount.to_f * f.fine_amount.to_f * 0.01))
          end
        end
                
        _data[:opening_journal] = op_bal
        
        _data
      end
      
      def student_advanced_search_csv(data_hash)
        data ||= Array.new
        data << ["#{t('students')} #{t('listed_by')} "+"#{ }"+data_hash[:searched_for].downcase]
        temp = ["#{t('name')}", "#{t('batch')}", "#{t('adm_no')}", "#{t('familyid')}"]
        temp.push("#{t('roll_no')}") if Configuration.enabled_roll_number?
        if (((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:doa_option].present?)) and ((!data_hash[:parameters].present?) or (!data_hash[:parameters][:advv_search].present?) or (!data_hash[:parameters][:advv_search][:dob_option].present?)))
          temp.push("#{t('admission_date')}")
        elsif (((!data_hash[:parameters].present?) or (!data_hash[:parameters][:advv_search].present?) or (!data_hash[:parameters][:advv_search][:doa_option].present?)) and ((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:dob_option].present?)))
          temp.push("#{t('date_of_birth')}")
        elsif (((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:doa_option].present?)) and ((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:dob_option].present?)))
          temp.push("#{t('admission_date')}")
          temp.push("#{t('date_of_birth')}")
        end
        temp.push("#{t('leaving_date')}") if data_hash[:parameters][:search][:is_active_equals]=="false"
        data << temp
        data_hash[:students].each do |row|
          temp = [row.full_name.to_s, row.batch.full_name.to_s, row.admission_no.to_s, row.familyid.to_s ]
          temp.push(row.roll_number) if Configuration.enabled_roll_number?
          if (((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:doa_option].present?)) and ((!data_hash[:parameters].present?) or (!data_hash[:parameters][:advv_search].present?) or (!data_hash[:parameters][:advv_search][:dob_option].present?)))
            temp.push(format_date(row.admission_date))
          elsif (((!data_hash[:parameters].present?) or (!data_hash[:parameters][:advv_search].present?) or (!data_hash[:parameters][:advv_search][:doa_option].present?)) and ((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:dob_option].present?)))
            temp.push(format_date(row.date_of_birth))
          elsif (((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:doa_option].present?)) and ((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:dob_option].present?)))
            temp.push(format_date(row.admission_date))
            temp.push(format_date(row.date_of_birth))
          end
          temp.push(format_date(row.date_of_leaving, :format => :short)) if data_hash[:parameters][:search][:is_active_equals]=="false"
          data << temp
        end
        return data
      end
    end
  end
end