class NumberSequence < ActiveRecord::Base
  validates_presence_of :name, :sequence_type
  # return a new sequence number as per suffix, prefix (sequence prefix) and sequence types
  # 1. receipt number [ if sequence type is receipt_no]
  # 2. invoice number [ if sequence type is invoice_no]
  # Note: 1. suffix is starting receipt number set in receipt number sets or default starting receipt number
  #       2. prefix is sequence prefix required in a receipt number
  #       3. sequence type is type of sequence required. [in future if needed, just use another sequence_type like voucher_no etc.]
  #       4. receipt_no is used just for explainations in #1,#2.
  def self.generate_next_number suffix, prefix, sequence_type
    school_id = MultiSchool.current_school.id
    initial_suffix_number = (suffix.zero? ? 1 : suffix)
    # setting instance variable in mysql session as initial suffix or a starting number
    q_set_initial_value = "SET @updated_next_number = #{initial_suffix_number}";
    # attempts to insert a record with set starting number with prefix/sequence
    # if insertion fails then it retrievs next possible sequence number, increments sets to session and updates in db
    q_insert_or_update = "INSERT INTO `number_sequences`
                                                           (`name`, `sequence_type`, `next_number`, `created_at`, 
                                                            `updated_at`, `school_id`) 
                                              VALUES ('#{prefix}', '#{sequence_type}', #{initial_suffix_number}, 
                                                             NOW(), NOW(), #{school_id}) 
              ON DUPLICATE KEY UPDATE next_number = @updated_next_number := 
                                                                                  (CASE WHEN next_number < #{initial_suffix_number} 
                                                                                                       THEN #{initial_suffix_number}
                                                                                              ELSE next_number + 1 
                                                                                              END),
                                                          updated_at = NOW();"
    # last updated sequence number is returned as newly generated number to be used from set session.
    q_select_next_number = "SELECT @updated_next_number AS next_number;"
    # connection pool is used to ensure session setted variable
    # @updated_next_number remains same throughout block of steps
    ActiveRecord::Base.connection_pool.with_connection do 
      ActiveRecord::Base.connection.execute(q_set_initial_value)
      ActiveRecord::Base.connection.execute(q_insert_or_update)
      ActiveRecord::Base.connection.execute(q_select_next_number).all_hashes      
    end
  end
end