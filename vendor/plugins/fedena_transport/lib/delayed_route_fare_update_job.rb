class DelayedRouteFareUpdateJob
  
  def initialize(obj)
    @route_id = obj
  end
  
  def perform
    @route = Route.find(@route_id)
    load_data
    @route.fare_updating_status = 1
    @route.send(:update_without_callbacks)
  end
  
  def load_data
    @transports = Transport.all(:conditions => ["(pickup_route_id = ? OR drop_route_id = ?) AND auto_update_fare = ?  AND 
      (transports.receiver_type='Student' AND transports.academic_year_id = batches.academic_year_id) ", @route_id, @route_id, true], 
    :joins => "INNER JOIN students on students.id = transports.receiver_id
              INNER JOIN batches on batches.id = students.batch_id")
    employee_transports = Transport.all(:conditions => ["(pickup_route_id = ? OR drop_route_id = ?) AND auto_update_fare = ?  AND transports.receiver_type='Employee'", @route_id, @route_id, true])
    @transports = @transports+employee_transports if employee_transports.present?
    @transports.each do |trans|
      parameters = {:mode => trans.mode, :pickup_route => trans.pickup_route_id, 
        :pickup_stop => trans.pickup_stop_id, :drop_route => trans.drop_route_id, :drop_stop => trans.drop_stop_id
      }
      trans.bus_fare = Transport.calculate_fare(parameters)
      trans.send(:update_without_callbacks)
      update_fees = Configuration.get_config_value("UpdateUnpaidTransportFee").to_i
      if update_fees == 1
        sql = "UPDATE transport_fees LEFT OUTER JOIN transport_fee_finance_transactions ON transport_fees.id = transport_fee_finance_transactions.transport_fee_id 
LEFT OUTER JOIN finance_transactions ON finance_transactions.id = transport_fee_finance_transactions.finance_transaction_id 
SET transport_fees.bus_fare = #{trans.bus_fare}, transport_fees.balance = #{trans.bus_fare} WHERE transport_fees.receiver_id = #{trans.receiver_id} AND transport_fees.school_id = #{trans.school_id} 
AND transport_fees.is_paid = false AND finance_transactions.id IS NULL AND transport_fees.receiver_type = '#{trans.receiver_type}'"
        TransportFee.connection.execute(sql)
      end
    end
  end
  
end
