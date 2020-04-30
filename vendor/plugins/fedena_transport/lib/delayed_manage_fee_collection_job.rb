class DelayedManageFeeCollectionJob
  
  def initialize(obj)
    @transport_fees = obj
  end
  
  def perform
    @transport_fees.each do |tf|
      tf.destroy
    end
  end
  
end