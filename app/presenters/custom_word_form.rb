class CustomWordForm < Tableless
  
  column :disable_custom_words, :boolean
  
  has_many :custom_translations
  
  accepts_nested_attributes_for :custom_translations, :allow_destroy => true

  def build_custom_words
    hsh = {}
    values = CustomTranslation.make_form
    values.each do |term, val|
      hsh[term] = []
      val.each do |type, v|
        hsh[term] << self.custom_translations.build(:key => v[:key], :translation => v[:translation], 
          :term => term, :term_type => type.to_s, :default_value => v[:default_value])
      end
    end
    hsh.each{|h, val| hsh[h] = val.sort_by(&:term_type)}
    hsh
  end
  
  def save_translations
    config = Configuration.first(:conditions => {:config_key => 'disable_custom_words'})
    Configuration.set_value('disable_custom_words', disable_custom_words)
    unless disable_custom_words
      translations = CustomTranslation.all
      changed = false
      custom_translations.each do |tran|
        terminology = translations.detect{|t| t.key==tran.key}
        if terminology.present?
          unless terminology.translation == tran.translation.downcase
            terminology.update_attributes(:translation => (tran.translation.blank? ? 
                  tran.default_value.downcase : tran.translation.downcase))
            changed = true
          end
        else
          CustomTranslation.create(:key => tran.key, :translation => (tran.translation.blank? ? tran.default_value.downcase : tran.translation.downcase))
          changed = true
        end
      end
      self.custom_translations = []
    end
    CustomTranslation.flush_cache
  end
  
  
  
  
  class << self
    
    def initialize_form
      config = Configuration.first(:conditions => {:config_key => 'disable_custom_words'})
      config = Configuration.create(:config_key => 'disable_custom_words', :config_value => true) if config.nil?
      new(:disable_custom_words => Configuration.custom_words_disabled?)
    end
    
  end  
end
