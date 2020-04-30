module FedenaTransport

  def self.attach_overrides
    Dispatcher.to_prepare :fedena_transport do
      ::ArchivedStudent.instance_eval { has_one :transport, :primary_key => 'former_id',:foreign_key => 'receiver_id', :conditions => "receiver_type = 'Student'"}
      ::ArchivedStudent.instance_eval { include ArchivedStudentExtension }
    end
  end
  
  module ArchivedStudentExtension
    def transport_fees_by_batch(batch_id,order=nil)
      unless order.present?
        order = "transport_fees.transaction_id"
      end
      TransportFee.all(:conditions => ["transport_fees.receiver_id = ? AND
                                        transport_fees.groupable_id = ? AND transport_fees.groupable_type = 'Batch' AND
                                        (fa.id IS NULL OR fa.is_deleted = false)", former_id, batch_id],
        :joins => "INNER JOIN transport_fee_collections tfc ON tfc.id = transport_fees.transport_fee_collection_id
                                   LEFT JOIN fee_accounts fa ON fa.id = tfc.fee_account_id",
        :order => order)
    end
    
  end
  
  
  module StudentExtension
    def self.included(base)
      base.instance_eval do
        attr_accessor :enable_transport
        has_many :transport_fees, :as => 'receiver'
        has_many :transports, :as => 'receiver', :dependent => :destroy
        has_many :archived_transports, :as => 'receiver', :dependent => :destroy
        has_one :transport, :as => 'receiver', :dependent => :destroy, :include => :academic_year, :conditions => "academic_years.is_active = true"
      

        accepts_nested_attributes_for :transport_fees
        accepts_nested_attributes_for :transport, :allow_destroy => true

        named_scope :student_transport_details, lambda { |academic_year_id|
          {:select => "students.id, CONCAT(first_name, ' ', middle_name, ' ', last_name) AS name, sibling_id, immediate_contact_id,
admission_no, roll_number, CONCAT(courses.code, '-', batches.name) AS batch_full_name, batches.id AS batch_id, 
IF(transports.id <=> NULL, false, true) AS allocation_status, transports.mode AS allocation_type, 
p_route.name AS pickup_route, d_route.name AS drop_route, p_stop.name AS pickup_stop, d_stop.name AS drop_stop,
            p_vehicle.vehicle_no AS pickup_vehicle, d_vehicle.vehicle_no AS drop_vehicle",
            :joins => "INNER JOIN batches ON batches.id = students.batch_id
INNER JOIN courses ON courses.id = batches.course_id 
LEFT OUTER JOIN transports on transports.receiver_type = 'Student' AND transports.receiver_id = students.id AND transports.academic_year_id = #{academic_year_id}
LEFT OUTER JOIN routes AS p_route ON p_route.id = transports.pickup_route_id 
LEFT OUTER JOIN vehicles AS p_vehicle ON p_route.vehicle_id = p_vehicle.id 
LEFT OUTER JOIN routes AS d_route ON d_route.id = transports.drop_route_id 
LEFT OUTER JOIN vehicles AS d_vehicle ON d_route.vehicle_id = d_vehicle.id 
LEFT OUTER JOIN vehicle_stops AS p_stop ON p_stop.id = transports.pickup_stop_id 
LEFT OUTER JOIN vehicle_stops AS d_stop ON d_stop.id = transports.drop_stop_id",
            :group => 'students.id',
            :include => [:immediate_contact, :father, :mother]
          }
        }

        named_scope :batch_wise_student_transport, lambda { |batch_ids|
          {:conditions => ["batches.id IN (?)", batch_ids]
          }
        }

        named_scope :alotted_student_transports, :conditions => ["transports.id IS NOT NULL"]

        named_scope :route_filter, lambda { |route_type, value|
          {
            :select => "#{route_type}_stop AS stop, #{route_type}_vehicle AS vehicle",
            :conditions => ["#{route_type}_route_id = ?", value]
          }
        }

        named_scope :student_transport_attendance_details, lambda { |academic_year_id|
          {:select => "students.id, CONCAT(first_name, ' ', middle_name, ' ', last_name) AS name, sibling_id, immediate_contact_id,
admission_no, roll_number, CONCAT(courses.code, ' ', batches.name) AS batch_full_name, batches.id AS batch_id, 
IF(transports.id <=> NULL, false, true) AS allocation_status, transports.mode AS allocation_type, 
p_route.name AS pickup_route, d_route.name AS drop_route, p_stop.name AS pickup_stop, d_stop.name AS drop_stop",
            :joins => "INNER JOIN batches ON batches.id = students.batch_id
INNER JOIN courses ON courses.id = batches.course_id 
LEFT OUTER JOIN transports on transports.receiver_type = 'Student' AND transports.receiver_id = students.id AND transports.academic_year_id = #{academic_year_id}
LEFT OUTER JOIN routes AS p_route ON p_route.id = transports.pickup_route_id 
LEFT OUTER JOIN routes AS d_route ON d_route.id = transports.drop_route_id 
LEFT OUTER JOIN vehicle_stops AS p_stop ON p_stop.id = transports.pickup_stop_id 
LEFT OUTER JOIN vehicle_stops AS d_stop ON d_stop.id = transports.drop_stop_id",
            :group => 'students.id',
            :include => [:immediate_contact, :father, :mother]
          }
        }

        named_scope :transport_sort_order, lambda { |s_order|
          {:order => s_order
          }
        }
        before_destroy :handle_transport_data
        DependencyHook.make_dependency_hook(:transport_batch_fee, :student, :warning_message => :transport_fee_are_already_assigned) do
          self.batch_transport_fees_exist
        end
        DependencyHook.make_dependency_hook(:transport_batch_fee_value, :student) do
          self.transport_fee_collections
        end
        DependencyHook.make_dependency_hook(:fedena_transport_dependency, :student, :warning_message => :transport_present) do
          self.transport_dependencies
        end
      end
      #TODO implement logic
      def has_pending_transport_fees?
        pending_count=TransportFee.count(:all,
          :joins => "INNER JOIN transport_fee_collections tfc
                                                            ON tfc.id = transport_fees.transport_fee_collection_id
                                               LEFT OUTER JOIN fee_accounts fa ON fa.id = tfc.fee_account_id
                                                    INNER JOIN students on students.id = transport_fees.receiver_id",
          :conditions => ["(fa.id IS NULL OR fa.is_deleted = false) AND
                                                          transaction_id IS NULL AND students.id = ?", self.id]
        )
        pending_count>0
      end

      def handle_transport_data
        archived_record = ArchivedStudent.find_by_former_id(self.id)
        self.transports.each { |t| t.archive_transport({:remove_fare => 1}, archived_record.id, archived_record.class.to_s) } if archived_record.present?
      end

    end


    def transport_fee_collections
      TransportFeeCollection.find(:all,
        :joins => "LEFT OUTER JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id
                                                  INNER JOIN transport_fees tf
                                                          ON transport_fee_collections.id = tf.transport_fee_collection_id",
        :conditions => "tf.receiver_id = #{self.id} and tf.receiver_type='Student' and
                                                  transport_fee_collections.is_deleted = 0 and tf.is_active=1 and
                                                  (fa.id IS NULL OR fa.is_deleted = false)")
    end

    def transport_fee_collections_with_dues
      TransportFeeCollection.find(:all,
        :joins => "LEFT OUTER JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id
                                                  INNER JOIN transport_fees tf
                                                          ON transport_fee_collections.id = tf.transport_fee_collection_id",
        :conditions => "tf.receiver_id = #{self.id} and tf.receiver_type='Student' and
                                                  transport_fee_collections.is_deleted = 0 and tf.is_active=1 and
                                                  tf.balance <> 0 and (fa.id IS NULL OR fa.is_deleted = false)")
    end

    def transport_dependencies
      return false if self.transport.present? or self.transport_fees.active.present?
      return true
    end

    def transport_fee_balance(fee_collection_id)
      fee_collection = TransportFeeCollection.find_by_id(fee_collection_id,
        :joins => "LEFT JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id",
        :conditions => "fa.id IS NULL OR fa.is_deleted = false")
      return (fee_collection.present? ? self.transport_fee_transactions(fee_collection).try(:balance) : 0)
    end

    def transport_fee_is_paid(fee_collection)
      transportfee = self.transport_fee_transactions(fee_collection)
      return transportfee.is_paid
    end

    def transport_fee_fine(fee_collection_id)
      fee_collection= TransportFeeCollection.find(fee_collection_id)
      transportfee = self.transport_fee_transactions(fee_collection)
      discount = transportfee.total_discount_amount
      fine_amount = transportfee.auto_fine_amount(fee_collection, discount, transportfee)
      paid_fine = transportfee.finance_transactions.present? ?
        transportfee.finance_transactions.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount) : 0.0.to_f
      return (fine_amount - paid_fine).to_f
    end

    def transport_fee_transactions(fee_collection)
      TransportFee.find_by_transport_fee_collection_id_and_receiver_id(fee_collection.id, self.id)
    end

    def transport_fee_collections_exists
      transport_fee_collections.empty?
    end

    def batch_transport_fees_exist
      transport_fees.select { |t| t.try(:transport_fee_collection).try(:batch_id) == batch_id and !t.try(:transport_fee_collection).try(:is_deleted) }.empty?
    end

    def transport_fees_by_batch(batch_id,order=nil)
      unless order.present?
        order = "transport_fees.transaction_id"
      end
      TransportFee.all(:conditions => ["transport_fees.is_active = ? AND transport_fees.receiver_id = ? AND
                                        transport_fees.groupable_id = ? AND transport_fees.groupable_type = 'Batch' AND
                                        (fa.id IS NULL OR fa.is_deleted = false)", true, id, batch_id],
        :joins => "INNER JOIN transport_fee_collections tfc ON tfc.id = transport_fees.transport_fee_collection_id
                                   LEFT JOIN fee_accounts fa ON fa.id = tfc.fee_account_id",
        :order => order)
    end

    def stu_batch_name
      batch.full_name
    end

    def transport_allocation_status
      (allocation_status == "1" ? t('alloted') : t('not_alloted'))
    end

    def transport_allocation_type
      t(Transport::TRANSPORT_MODE[allocation_type.to_i]) if allocation_type.present?
    end

    def stop(route_type)
      send("#{route_type}_stop")
    end

    def vehicle_name(route_type)
      send("#{route_type}_vehicle")
    end
  end 
end
  