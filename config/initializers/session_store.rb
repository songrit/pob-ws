# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_wwp_session',
  :secret      => 'b4d70fd651ae4c9303be9b95450d0f0c05b4dcfc0d8d72cefae5d525f138321d3cd719548f2e8fb244445dae6345a6e6d4eac909b6234c907a920e394c3d6a16'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
