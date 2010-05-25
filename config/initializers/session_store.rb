# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_somatics_session',
  :secret      => '521d278c2326a10f34c5bdc608f59d2c7523adea949a6523e0210bfe825d6de4eeed9aac57ff06ab4af1071f785daf8a88f5fcce45cf031eb400a4048d292710'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
