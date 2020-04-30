class AdditionalSetting < ActiveRecord::Base
  belongs_to :owner, :polymorphic=>true
  serialize :settings
  before_save :clear_white_spaces

  def settings_to_sym
    if settings.is_a? Hash
      return settings.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    end
    return settings
  end

  protected

  def clear_white_spaces
    clean_white_space_in_hash(self.settings)
  end

  def clean_white_space_in_hash(hsh)
    hsh.each do |k,v|
      if v.is_a? Hash
        clean_white_space_in_hash(v)
      elsif v.is_a? String
        hsh[k]=v.strip
      end
    end
  end
  
end
