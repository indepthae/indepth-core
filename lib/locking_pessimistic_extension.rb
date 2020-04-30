module Locking
  module PessimisticExtension
    # Wraps the passed block in a transaction, locking the object
    # before yielding. You can pass the SQL locking clause
    # as argument (see <tt>lock!</tt>).
    def with_lock(lock = true)
      transaction do
        lock!(lock)
        yield
      end
    end
  end
end
## TO DO :: to make it globally available, include Locking::PessimisticExtension
#              against ActiveRecord::Base inside config/initializers/core_extensions.rb
#  OR add ActiveRecord::Base.send :include, Locking::PessimisticExtension suitably