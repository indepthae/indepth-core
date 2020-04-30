class DocumentUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :document
  
  def toggle_favorite
    self.is_favorite = self.is_favorite? ? false : true
    self.save
    self.is_favorite ? t('documents.flash4') : t('documents.flash5')
  end
  
end
