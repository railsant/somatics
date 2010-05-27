require File.expand_path(File.dirname(__FILE__) + "/lib/insert_routes.rb")
require 'digest/sha1'

module AuthenticatedGenerator
  attr_reader   :session_controller_name,
                :session_controller_class_path,
                :session_controller_file_path,
                :session_controller_class_nesting,
                :session_controller_class_nesting_depth,
                :session_controller_class_name,
                :session_controller_singular_name,
                :session_controller_plural_name,
                :session_controller_routing_name,           
                :session_controller_routing_path,           
                :session_controller_controller_name         
  alias_method  :session_controller_file_name,  :session_controller_singular_name
  alias_method  :session_controller_table_name, :session_controller_plural_name
  
  def initialize_session_controller_name
    @session_controller_name = "#{@name}_sessions"

    base_name, @session_controller_class_path, @session_controller_file_path, @session_controller_class_nesting, @session_controller_class_nesting_depth = extract_modules(@session_controller_name)
    @session_controller_class_name_without_nesting, @session_controller_file_name, @session_controller_plural_name = inflect_names(base_name)
    @session_controller_singular_name = @session_controller_file_name.singularize
    if @session_controller_class_nesting.empty?
      @session_controller_class_name = @session_controller_class_name_without_nesting
    else
      @session_controller_class_name = "#{@session_controller_class_nesting}::#{@session_controller_class_name_without_nesting}"
    end
    @session_controller_routing_name  = @session_controller_singular_name
    @session_controller_routing_path  = @session_controller_file_path.singularize
    @session_controller_controller_name = @session_controller_plural_name
  end
  
  def has_rspec?
    spec_dir = File.join(RAILS_ROOT, 'spec')
    options[:rspec] ||= (File.exist?(spec_dir) && File.directory?(spec_dir)) unless (options[:rspec] == false)
  end

  #
  # !! These must match the corresponding routines in by_password.rb !!
  #
  def secure_digest(*args)
    Digest::SHA1.hexdigest(args.flatten.join('--'))
  end
  def make_token
    secure_digest(Time.now, (1..10).map{ rand.to_s })
  end
  def password_digest(password, salt)
    digest = $rest_auth_site_key_from_generator
    $rest_auth_digest_stretches_from_generator.times do
      digest = secure_digest(digest, salt, password, $rest_auth_site_key_from_generator)
    end
    digest
  end

  #
  # Try to be idempotent:
  # pull in the existing site key if any,
  # seed it with reasonable defaults otherwise
  #
  def load_or_initialize_site_keys
    case
    when defined? REST_AUTH_SITE_KEY
      if (options[:old_passwords]) && ((! REST_AUTH_SITE_KEY.blank?) || (REST_AUTH_DIGEST_STRETCHES != 1))
        raise "You have a site key, but --old-passwords will overwrite it.  If this is really what you want, move the file #{site_keys_file} and re-run."
      end
      $rest_auth_site_key_from_generator         = REST_AUTH_SITE_KEY
      $rest_auth_digest_stretches_from_generator = REST_AUTH_DIGEST_STRETCHES
    when options[:old_passwords]
      $rest_auth_site_key_from_generator         = nil
      $rest_auth_digest_stretches_from_generator = 1
      $rest_auth_keys_are_new                    = true
    else
      $rest_auth_site_key_from_generator         = make_token
      $rest_auth_digest_stretches_from_generator = 10
      $rest_auth_keys_are_new                    = true
    end
  end
  def site_keys_file
    File.join("config", "initializers", "site_keys.rb")
  end
end