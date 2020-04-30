# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_runner_session',
  :secret      => '97904588e7fdeae4941e11b5df3cf3c4c35a0f1d5f50f1525f1ce82a58412c4b76b7dc1a802e091fb4df10ad69646c7f09cc18aa9ac7c8ca5c0de3779bd1536d'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
