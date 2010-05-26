# config/initializers/mail.rb
ActionMailer::Base.delivery_method = :smtp

# Modify the following SMTP Settings
ActionMailer::Base.smtp_settings = {
  :tls => true,
  :address => "smtp.gmail.com",
  :port => "587",
  :domain => "somatics.hk",
  :authentication => :plain,
  :user_name => "noreply@somatics.hk",
  :password => "somaticspassowrd"
}


#ActionMailer::Base.default_content_type = "text/html"

#FIXME use other's smtp server recently
#TODO use fb account to login http://www.madebymany.co.uk/tutorial-for-restful_authentication-on-rails-with-facebook-connect-in-15-minutes-00523