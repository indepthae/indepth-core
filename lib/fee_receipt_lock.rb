# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module FeeReceiptLock
    
  def self.memcache_on?
    @@cache ||= Rails.cache 
    @@cache.is_a? ActiveSupport::Cache::MemCacheStore
  end
  
  def self.current_school_id
    MultiSchool.current_school.id
  end
  
  def self.cache_key
    "receipt_number/#{current_school_id}"
  end
  
  def self.receipt_no(receipt_no)
    if cache_has_receipt_no?
      receipt_no = next_receipt_no
      write_to_cache(receipt_no)
      return receipt_no
    else
      write_to_cache(receipt_no) if memcache_on? ## TODO
      return receipt_no
    end
  end
    
  def self.cache_has_receipt_no?
    return false unless memcache_on?
    @@cache.exist?(cache_key)
  end
  
  
  def self.next_receipt_no
    saved_receipt_no = /(.*?)(\d*)$/.match(receipt_number_in_cache)
    saved_receipt_no[1] + saved_receipt_no[2].next
  end
  
  
  #read From cache
  def self.receipt_number_in_cache
    @@cache.fetch(cache_key).to_s
  end
  
  def self.clear_cache
    @@cache.delete(cache_key) if memcache_on?
  end
    
  def self.write_to_cache(receipt_no)
    clear_cache
    @@cache.write(cache_key, receipt_no, :expires_in => 10.seconds)
  end
  
end
