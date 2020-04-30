module FedenaEmailAlert

  class AlertMailPayloadCollection

    def initialize
      @collection = []
    end

    def << (entry)
      @collection << entry
    end

    def perform
      @collection.each do |alert_payload|
        alert_payload.process
      end
    end

    # queue name for DJ
    def job_queue_name
      'email'
    end

  end

end