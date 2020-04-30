class ArchivedTransport < ActiveRecord::Base
  
  belongs_to :receiver, :polymorphic=>true
    
  # this will revert transport details of a single passenger during student/employee revert. 
  # Also it will revert the inactive fare(fare removed during archiving passenger)
  def revert_archived_transport(passenger_id, passenger_type)
    ActiveRecord::Base.transaction do
      transport = Transport.new(:receiver_id => passenger_id, :receiver_type => passenger_type, 
        :bus_fare => bus_fare, :pickup_route_id => pickup_route_id, :academic_year_id => academic_year_id,
        :pickup_stop_id => pickup_stop_id, :mode => mode, :drop_stop_id => drop_stop_id, :auto_update_fare => auto_update_fare, 
        :drop_route_id => drop_route_id, :applied_from => Date.today, :remove_fare => nil) 
      school_id = MultiSchool.current_school.id
      if remove_fare
        sql = "UPDATE transport_fees LEFT OUTER JOIN transport_fee_finance_transactions ON transport_fees.id = transport_fee_finance_transactions.transport_fee_id 
LEFT OUTER JOIN finance_transactions ON finance_transactions.id = transport_fee_finance_transactions.finance_transaction_id 
SET transport_fees.is_active = true WHERE transport_fees.receiver_id = #{passenger_id} AND transport_fees.school_id = #{school_id} 
AND transport_fees.is_paid = false AND finance_transactions.id IS NULL AND transport_fees.receiver_type = '#{passenger_type}'"
        TransportFee.connection.execute(sql)
      end
      if transport.save
        raise ActiveRecord::Rollback unless self.destroy
      end
    end
  end
end
