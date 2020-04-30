class DeleteDuplicateReceiptNumberAndAddUniqueness < ActiveRecord::Migration
  def self.up
    #to change group_concat maximum value of mysql
    unless FinanceTransaction.column_names.include?("school_id")
      add_column :finance_transactions,:school_id,:integer
    end
    i = 0
    change_setting_sql="SET SESSION group_concat_max_len = 1000000;"
    ActiveRecord::Base.connection.execute(change_setting_sql)

    #delete duplicate receipt number -  by double click
    rows = FinanceTransaction.all(:having=>"count(receipt_no)>1",:select=>"group_concat(id) as f_ids",:group=>"receipt_no,payee_id,school_id,finance_type,payee_type,finance_id,amount",:skip_multischool=>true)
    rows.each do |row|
      finance_ids = row.f_ids.split(",").to_a.flatten
      finance_ids.sort!
      finance_ids.shift
      finance_ids.each do |id|
        FinanceTransaction.find(id,:skip_multischool=>true).delete
      end
    end


    puts "Duplicate Transaction entry Deleted"
    #change  duplicate receipt number with new receipt number

    f = FinanceTransaction.all(:having=>"count(receipt_no)>1",:select=>"school_id,group_concat(id) as f_ids,receipt_no",:conditions=>"receipt_no IS NOT NULL",:group=>"receipt_no,school_id",:order=>"id",:skip_multischool=>true)
    f.each do |finance_transaction|
      i += 1
      receipt_split = /(.*?)(\d*)$/.match(finance_transaction.receipt_no)
      selected_receipt_no_prefix = receipt_split[1]
      finance_transaction_ids = finance_transaction.f_ids.split(",").to_a.sort
      finance_transaction_ids.shift
      finance_transaction_ids.each do |ft|
        if receipt_split[1].present?
          selected_transactions = FinanceTransaction.all(:conditions=>" receipt_no IS NOT NULL and school_id=#{finance_transaction.school_id} and receipt_no REGEXP '(#{selected_receipt_no_prefix})\d*' ",:skip_multischool=>true)
        else
          selected_transactions = FinanceTransaction.all(:conditions=>"receipt_no IS NOT NULL and school_id=#{finance_transaction.school_id}",:skip_multischool=>true)
        end
        last_receipt_no_sufix = selected_transactions.collect{ |k| k.receipt_no.scan(/\d+$/i).last.to_i }.max
        if selected_receipt_no_prefix.present?
          receipt_number = selected_receipt_no_prefix + last_receipt_no_sufix.next.to_s
        else
          receipt_number = last_receipt_no_sufix.next
        end
        sql = "UPDATE finance_transactions SET receipt_no='#{receipt_number}' WHERE id=#{ft}"
        puts "#{finance_transaction.receipt_no} - updated to #{receipt_number} in row#{i}"
        ActiveRecord::Base.connection.execute(sql)
      end
    end
    puts "Duplicate receipt Updated"
    #add index

    add_index :finance_transactions, [:receipt_no, :school_id], :unique => true

  end



  def self.down
    #remove index
    remove_index :finance_transactions, [:receipt_no, :school_id], :unique => true
  end
end
