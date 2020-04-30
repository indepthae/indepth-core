# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class MessageAttachmentsAssoc < ActiveRecord::Base
  belongs_to :message
  belongs_to :message_attachment
end
