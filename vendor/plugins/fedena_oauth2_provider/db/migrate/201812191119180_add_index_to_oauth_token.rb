class AddIndexToOauthToken < ActiveRecord::Migration
  def self.up
    unless index_exists('index_to_access_token')
      add_index :oauth_tokens,[:access_token],:name => 'index_to_access_token'
      add_index :oauth_tokens,[:user_id],:name => 'index_to_user_id'
    end
  end

  def self.down
    remove_index :oauth_tokens,[:access_token],:name => 'index_to_access_token'
    remove_index :oauth_tokens,[:user_id],:name => 'index_to_user_id'
  end
  
  private
  
  def self.index_exists(name)
    ActiveRecord::Base.connection.indexes(:oauth_tokens).select{|obj| obj.name == name}.present?
  end

end
