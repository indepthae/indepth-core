class PopulateIsPaidInTransportFee < ActiveRecord::Migration
  require 'logger'
  def self.up
    log = Logger.new("log/populate_is_paid_in_transport_fee_log-#{Date.today.to_s}.log")
    t = Time.now
    updated_count = 0
    School.find_in_batches({:batch_size => 500}) do |schools|
      schools.each_with_index do |school, i|
        puts "\n==================================================="
        puts "Processing school : #{school.id} - #{school.name}"
        puts "===================================================\n"
        log.info("=========================================")
        log.info ("School id & name : #{school.id} #{school.name}")
        log.info("=========================================")
        sql="UPDATE `transport_fees` SET `is_paid`= CASE"
        MultiSchool.current_school = school
        tf_ids = []
        TransportFee.find_in_batches({:batch_size => 500, 
            :include =>[:transport_fee_discounts, :finance_transactions, {:transport_fee_collection => {:fine => :fine_rules}}]}) do |transport_fees|
          transport_fees.each do |transport_fee|            
            if transport_fee.transport_fee_collection.present?
              if transport_fee.bus_fare.present?
                log.info("=========================================")
                log.info ("Transport Fee id & Collection id and Name : #{transport_fee.id}, #{transport_fee.transport_fee_collection.id} #{transport_fee.transport_fee_collection.name}")
                log.info("=========================================")
                updated_count = updated_count.next
                tf_ids << transport_fee.id
                discount_amount = 0
                transport_fee.transport_fee_discounts.each{|tfd| 
                  discount_amount = discount_amount + (tfd.is_amount ? tfd.discount : (transport_fee.bus_fare*(tfd.discount/100)))} if transport_fee.transport_fee_discounts.present?
                finance_transaction_amount = 0
                transport_fee.finance_transactions.each do |finance_transaction|
                  finance_transaction_amount += (finance_transaction.amount - (finance_transaction.fine_amount.present? ? finance_transaction.fine_amount : 0)) 
                end
                days=(Date.today-transport_fee.transport_fee_collection.due_date.to_date).to_i
                auto_fine=transport_fee.transport_fee_collection.fine
                auto_fine_amount=0
                bal= (transport_fee.bus_fare-discount_amount).to_f
                if days > 0 and auto_fine.present?
                  fine_rule=auto_fine.fine_rules.find(:last, 
                    :conditions => ["fine_days <= '#{days}' and created_at <= '#{transport_fee.transport_fee_collection.created_at}'"], 
                    :order => 'fine_days ASC')
                  if fine_rule.present?
                    auto_fine_amount=fine_rule.is_amount ? fine_rule.fine_amount : (bal*fine_rule.fine_amount)/100 
                    auto_fine_amount=auto_fine_amount-transport_fee.finance_transactions.find(:all, 
                      :conditions => ["description=?", 'fine_amount_included']).sum(&:auto_fine)
                  end
                end
                tax_amount = ((transport_fee.tax_enabled and transport_fee.tax_amount.present?) ? transport_fee.tax_amount : 0)
                is_paid = (transport_fee.bus_fare - discount_amount + tax_amount + auto_fine_amount - finance_transaction_amount) == 0
                log.info("=========================================")
                log.info("is_paid : #{is_paid}")
                log.info("=========================================")
                sql += " WHEN `id` = #{transport_fee.id} THEN #{is_paid} " 
              end
            end
          end
        end
        if tf_ids.present?
          sql += " END WHERE `id` in (#{tf_ids.join(',')});"
          log.info("=========================================")
          log.info(sql)
          log.info("=========================================")
          ActiveRecord::Base.connection.execute(sql)
        end
      end
    end
    t2 = Time.now
    log.info("=========================================")
    log.info("start at #{t}")
    log.info("end at #{t2}")
    log.info("updated #{updated_count} Transport Fees")
    log.info("=========================================")
    puts "\nstart at #{t} \n"
    puts "\nend at #{t2}\n"
    puts "\nupdated #{updated_count} Transport Fees \n"
  end

  def self.down
  end
end
