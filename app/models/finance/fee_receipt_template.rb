# Model holds logic for multiple fee receipt templates
# A receipt template comprise of
#     name                              : template name,
#     header_content                    : html content to be embedded for receipt header - A4 (mandatory)
#                                                                     [optionally can be used for A5 landscape]
#     footer_content                    : plain text to be embedded for receipt footer (optional)
#     header_content_a5_portrait        : html content to be embedded for receipt header - A5 portrait (optional)
#     header_content_thermal_responsive : html content to be embedded for receipt header - Thermal (optional)
class FeeReceiptTemplate < ActiveRecord::Base
  has_many :transaction_receipts
  
  has_many :finance_category_receipt_templates
  has_many :finance_fee_categories, :through => :finance_category_receipt_templates, :source => :category,
    :source_type => "FinanceFeeCategory"
  has_many :finance_transaction_categories, :through => :finance_category_receipt_templates, :source => :category,
    :source_type => "FinanceTransactionCategory"
  after_save :update_redactor
  attr_accessor :redactor_to_update, :redactor_to_delete
  xss_terminate :except => [:header_content, :header_content_thermal_responsive, :header_content_a5_portrait]
  validates_presence_of :name, :header_content
  validates_uniqueness_of :name
  validates_format_of :name, :with => /^[a-zA-Z0-9\s]*$/, :message => :special_characters_not_valid

  # validates if receipt template is linked to FinanceFeeCategory / FinanceTransactionCategory
  def has_assignments?
    return (self.finance_category_receipt_templates.last.present? or self.finance_category_receipt_templates.first.present?)
  end

  # updates for paperclip path from temp to fedena wise paperclip object path
  def update_redactor
    RedactorUpload.update_redactors(self.redactor_to_update,self.redactor_to_delete)
  end

  # deletion is not yet made for temp objects at redactor level
  def delete_redactors
    RedactorUpload.delete_after_create(self.content)
  end

  # returns header content for receipt pdf
  def header_content_for_pdf
    nok = Nokogiri::HTML(self.header_content)
    results = nok.xpath("//img")
    _header_content = self.header_content
    
    return _header_content if FedenaSetting.s3_enabled?
    
    results.each do |img_data|
      img_src = img_data.attributes['src'].value
      r = img_src.match /https:\/\/(.*)/
      next if $1.present?
      ru_id = img_src.match /.*redactor_uploads\/(.*)\/images.*/
      next unless $1.present?
      ru = RedactorUpload.find($1.gsub('/','').to_i)
      _header_content.gsub!(img_src, update_image_src(ru.image))
    end
    _header_content
  end

  # returns parsed image url as per enabled settings
  def update_image_src img, options = {}
    if FedenaSetting.s3_enabled? #and options[:s3].present? and options[:s3])      
      image_url = options[:style].present? ? img.url(options[:style].to_sym,false):img.url(:original,false)
      image_url = image_url.gsub('&amp;','&') if image_url.present?      
      image_url
      #      return (verify_http_https_file image_url) ? (image_tag image_url).gsub('&amp;','&') : ''
    else
      image_path = img.path
      return "file://#{Rails.root.join(image_path)}"
      #      return image_tag "file://#{Rails.root.join(image_path)}", options
    end
  end
end
