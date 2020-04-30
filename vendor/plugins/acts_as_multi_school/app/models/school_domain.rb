class SchoolDomain < ActiveRecord::Base
  belongs_to :linkable, :polymorphic=>true

  validates_format_of :domain, :with => /(^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[^ .]{2,}(:(6553[0-5]|655[0-2]\d|65[0-4]\d{2}|6[0-4]\d{3}|[1-5]\d{4}|[1-9]\d{0,3}))?$)|(^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(:(6553[0-5]|655[0-2]\d|65[0-4]\d{2}|6[0-4]\d{3}|[1-5]\d{4}|[1-9]\d{0,3}))?$)/ix
  validates_uniqueness_of :domain, :case_sensitive=>false, :message=>"this domain is not available"

  RESTRICTED_SUB_DOMAINS = open("#{File.dirname(__FILE__)}/../../config/restricted_domains.txt",'r').map {|line| Regexp.new "^#{line.strip}\\.#{MultiSchool.default_domain.gsub(/\./,'\.')}$"}

  after_destroy :clear_school_name_cache
  after_destroy :set_new_primary_domain
  after_save :process_primary_domain

  def validate
    self.errors.add(:domain, "this domain is reserved") unless RESTRICTED_SUB_DOMAINS.select{|d| d.match self.domain}.blank?
    self.errors.add(:domain, "domain limit exceeded") if linkable.school_domains.count >= 3 if linkable.present?
  end

  private

  def clear_school_name_cache
    Rails.cache.delete("current_school_name/#{domain}")
    return true
  end

  def process_primary_domain
    if is_primary? and linkable.present?
      primary_domains = linkable.school_domains.is_primary_is(true).collect(&:id) - [self.id]
      SchoolDomain.update_all("is_primary = 0","id in (#{primary_domains.join(',')})") if primary_domains.present?
    end
  end

  def set_new_primary_domain
    if is_primary? and linkable.present?
      primary_domains = linkable.school_domains.is_primary_is(false) - [self]
      primary_domains.last.update_attribute(:is_primary, true)
    end
  end

end