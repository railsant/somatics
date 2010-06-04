class ScaffoldGenerator < Rails::Generator::NamedBase
  default_options :skip_timestamps => false, 
                  :skip_migration => false, 
                  :force_plural => false,
                  :authenticated => false,
                  :include_activation => false

  attr_reader   :controller_name,
                :controller_class_path,
                :controller_file_path,
                :controller_class_nesting,
                :controller_class_nesting_depth,
                :controller_class_name,
                :controller_underscore_name,
                :controller_singular_name,
                :controller_plural_name,
                :controller_routing_name,
                :controller_routing_path,
                :controller_controller_name,
                :controller_file_name
  alias_method  :controller_file_name,  :controller_underscore_name
  alias_method  :controller_table_name, :controller_plural_name  
  attr_reader   :sessions_controller_name,
                :sessions_controller_class_path,
                :sessions_controller_file_path,
                :sessions_controller_class_nesting,
                :sessions_controller_class_nesting_depth,
                :sessions_controller_class_name,
                :sessions_controller_singular_name,
                :sessions_controller_plural_name,
                :sessions_controller_routing_name,           
                :sessions_controller_routing_path,           
                :sessions_controller_controller_name         
  alias_method  :sessions_controller_file_name,  :sessions_controller_singular_name
  alias_method  :sessions_controller_table_name, :sessions_controller_plural_name

  def initialize(runtime_args, runtime_options = {})
    super

    if @name == @name.pluralize && !options[:force_plural]
      logger.warning "Plural version of the model detected, using singularized version.  Override with --force-plural."
      @name = @name.singularize
      assign_names!(@name)
    end

    @controller_name = @name.pluralize

    base_name, @controller_class_path, @controller_file_path, @controller_class_nesting, @controller_class_nesting_depth = extract_modules(@controller_name)
    @controller_class_name_without_nesting, @controller_underscore_name, @controller_plural_name = inflect_names(base_name)
    @controller_singular_name = base_name.singularize
    if @controller_class_nesting.empty?
      @controller_class_name = @controller_class_name_without_nesting
    else
      @controller_class_name = "#{@controller_class_nesting}::#{@controller_class_name_without_nesting}"
    end
    @controller_routing_name  = @controller_singular_name
    @controller_routing_path  = @controller_file_path.singularize
    @controller_controller_name = @controller_plural_name
    
    if options[:authenticated]
      require File.expand_path(File.dirname(__FILE__) + "/lib/insert_routes.rb")
      require 'digest/sha1'
      initialize_sessions_controller_name
      load_or_initialize_site_keys
    end     
  end
  
  def initialize_sessions_controller_name
    @sessions_controller_name = "#{@controller_name}_sessions"

    base_name, @sessions_controller_class_path, @sessions_controller_file_path, @sessions_controller_class_nesting, @sessions_controller_class_nesting_depth = extract_modules(@sessions_controller_name)
    @sessions_controller_class_name_without_nesting, @sessions_controller_file_name, @sessions_controller_plural_name = inflect_names(base_name)
    @sessions_controller_singular_name = @sessions_controller_file_name.singularize
    if @sessions_controller_class_nesting.empty?
      @sessions_controller_class_name = @sessions_controller_class_name_without_nesting
    else
      @sessions_controller_class_name = "#{@sessions_controller_class_nesting}::#{@sessions_controller_class_name_without_nesting}"
    end
    @sessions_controller_routing_name  = @sessions_controller_singular_name
    @sessions_controller_routing_path  = @sessions_controller_file_path.singularize
    @sessions_controller_controller_name = @sessions_controller_plural_name
  end

  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions("#{controller_class_name}Controller", "#{controller_class_name}Helper")
      m.class_collisions(class_name)

      # Controller, helper, views, test and stylesheets directories.
      m.directory(File.join('app/models', class_path))
      m.directory(File.join('app/controllers', controller_class_path))
      m.directory(File.join('app/helpers', controller_class_path))
      m.directory(File.join('app/views', controller_class_path, controller_file_name))
      m.directory(File.join('app/views/layouts', controller_class_path))
      m.directory(File.join('test/functional', controller_class_path))
      m.directory(File.join('test/unit', class_path))
      m.directory(File.join('test/unit/helpers', class_path))
      m.directory(File.join('public/stylesheets', class_path))
      m.directory(File.join('public/javascripts', class_path))

      m.template 'controller.rb', File.join('app/controllers', controller_class_path, "#{controller_file_name}_controller.rb")
      m.template 'helper.rb',     File.join('app/helpers',     controller_class_path, "#{controller_file_name}_helper.rb")

      # Views and Builders
      m.template "partial_form.html.erb", File.join('app/views', controller_class_path, controller_file_name, "_form.html.erb")
      m.template "partial_list.html.erb", File.join('app/views', controller_class_path, controller_file_name, "_list.html.erb")
      m.template "partial_show.html.erb", File.join('app/views', controller_class_path, controller_file_name, "_show.html.erb")
      m.template "partial_edit.html.erb", File.join('app/views', controller_class_path, controller_file_name, "_edit.html.erb")
      m.template "view_index.html.erb",   File.join('app/views', controller_class_path, controller_file_name, "index.html.erb")
      m.template "view_new.html.erb",     File.join('app/views', controller_class_path, controller_file_name, "new.html.erb")
      m.template "view_show.html.erb",    File.join('app/views', controller_class_path, controller_file_name, "show.html.erb")
      m.template "builder_index.xml.builder", File.join('app/views', controller_class_path, controller_file_name, "index.xml.builder")
      m.template "builder_index.xls.builder", File.join('app/views', controller_class_path, controller_file_name, "index.xls.builder")
      m.template "builder_index.pdf.prawn",   File.join('app/views', controller_class_path, controller_file_name, "index.pdf.prawn")

      # Application, Layout and Stylesheet and Javascript.
      m.template 'layout.html.erb', File.join('app/views/layouts', controller_class_path, "application.html.erb"), :collision => :skip
      m.template 'application_helper.rb', File.join('app/helpers', controller_class_path, "application_helper.rb"), :collision => :skip
      m.template 'partial_menu.html.erb', File.join('app/views/layouts', controller_class_path, "_menu.html.erb"), :collision => :skip
      add_header(m, controller_file_name)
      m.template 'context_menu.js', 'public/javascripts/context_menu.js', :collision => :skip
      m.template 'select_list_move.js', 'public/javascripts/select_list_move.js', :collision => :skip
      # m.template('style.css', 'public/stylesheets/scaffold.css')

      m.template('functional_test.rb', File.join('test/functional', controller_class_path, "#{controller_file_name}_controller_test.rb"))
      m.template('helper_test.rb',     File.join('test/unit/helpers', controller_class_path, "#{controller_file_name}_helper_test.rb"))

      m.route_resources controller_file_name

      m.dependency 'model', [name] + @args, :collision => :skip unless options[:authenticated]
      
      generate_sessions_controller(m) if options[:authenticated]
    end
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

  protected
    # Override with your own usage banner.
    def banner
      "Usage: #{$0} scaffold ModelName [field:type, field:type]"
    end

    def add_options!(opt)
      opt.separator ''
      opt.separator 'Options:'
      opt.on("--skip-timestamps",
             "Don't add timestamps to the migration file for this model") { |v| options[:skip_timestamps] = v }
      opt.on("--skip-migration",
             "Don't generate a migration file for this model") { |v| options[:skip_migration] = v }
      opt.on("--force-plural",
             "Forces the generation of a plural ModelName") { |v| options[:force_plural] = v }
      opt.on("--use_layout",
             "Generate controller specific layout") { |v| options[:use_controller_layout] = v }
      opt.on("--authenticated",
             "Generate authenticated model") { |v| options[:authenticated] = true }
      opt.on("--include-activation",
             "Generate signup 'activation code' confirmation via email") { |v| options[:include_activation] = true }
    end

    def model_name
      class_name.demodulize
    end
    
  private
    def add_header(m, resource)
      # resource_list = resources.map { |r| r.to_sym.inspect }.join(', ')
      sentinel = '<!-- [HEADER] DO NOT REMOVE THIS LINE -->'
      
      m.gsub_file File.join('app/views/layouts', controller_class_path, "_menu.html.erb"), /(#{Regexp.escape(sentinel)})/mi do |match|
        "<li><%= link_to '#{resource.humanize}', '/#{resource}', :class => (match_controller?('#{controller_file_name}'))  ? 'selected' : ''%></li>\n#{match}"
      end
    end
    
    def generate_sessions_controller(m)
      # Check for class naming collisions.
      m.class_collisions sessions_controller_class_path, "#{sessions_controller_class_name}Controller", # Sessions Controller
                                                         "#{sessions_controller_class_name}Helper"
      m.class_collisions                                 "#{class_name}Mailer", "#{class_name}MailerTest", "#{class_name}Observer"
      m.class_collisions [], "#{class_name}AuthenticatedSystem", "#{class_name}AuthenticatedTestHelper"

      # Controller, helper, views, and test directories.
      m.directory File.join('app/controllers', sessions_controller_class_path)
      m.directory File.join('app/helpers', sessions_controller_class_path)
      m.directory File.join('app/views', sessions_controller_class_path, sessions_controller_name)
      m.directory File.join('app/views', class_path, "#{file_name}_mailer") if options[:include_activation]
      m.directory File.join('config/initializers')      
      m.directory File.join('test/functional', sessions_controller_class_path)
      m.directory File.join('test/fixtures', class_path)

      m.template 'authenticated/model.rb', File.join('app/models', class_path, "#{file_name}.rb")
      if options[:include_activation]
        %w( mailer observer ).each do |model_type|
          m.template "authenticated/#{model_type}.rb", File.join('app/models', class_path, "#{file_name}_#{model_type}.rb")
        end
      end

      m.template 'authenticated/sessions_controller.rb', File.join('app/controllers', sessions_controller_class_path, "#{sessions_controller_name}_controller.rb")

      m.template 'authenticated/authenticated_system.rb', File.join('lib', "#{file_name}_authenticated_system.rb")
      m.template 'authenticated/authenticated_test_helper.rb', File.join('lib', "#{file_name}_authenticated_test_helper.rb")
      m.template 'authenticated/site_keys.rb', site_keys_file
      
      m.template 'authenticated/test/sessions_functional_test.rb', File.join('test/functional', sessions_controller_class_path, "#{sessions_controller_name}_controller_test.rb")
      m.template 'authenticated/test/mailer_test.rb', File.join('test/unit', class_path, "#{file_name}_mailer_test.rb") if options[:include_activation]
      m.template 'authenticated/test/unit_test.rb', File.join('test/unit', class_path, "#{file_name}_test.rb")

      m.template 'authenticated/test/users.yml', File.join('test/fixtures', class_path, "#{table_name}.yml")                            
      m.template 'authenticated/helper.rb', File.join('app/helpers', sessions_controller_class_path, "#{sessions_controller_name}_helper.rb")

      # View templates
      m.template 'authenticated/login.html.erb',  File.join('app/views', sessions_controller_class_path, sessions_controller_name, "new.html.erb")
      m.template 'authenticated/signup.html.erb', File.join('app/views', controller_class_path, controller_file_name, "signup.html.erb")
      m.template 'authenticated/_model_partial.html.erb', File.join('app/views', controller_class_path, controller_file_name, "_#{file_name}_bar.html.erb")
      
      if options[:include_activation]
        # Mailer templates
        %w( activation signup_notification ).each do |action|
          m.template "authenticated/#{action}.erb", File.join('app/views', "#{file_name}_mailer", "#{action}.erb")
        end
      end
      
      unless options[:skip_migration]
        m.migration_template 'authenticated/migration.rb', 'db/migrate', :assigns => {
          :migration_name => "Create#{class_name.pluralize.gsub(/::/, '')}"
        }, :migration_file_name => "create_#{file_path.gsub(/\//, '_').pluralize}"
      end

      unless options[:skip_routes]
        # Note that this fails for nested classes -- you're on your own with setting up the routes.
        m.route_resource  sessions_controller_singular_name
        m.route_name("#{file_name}_signup",   "/#{controller_plural_name}/signup",   {:controller => controller_plural_name, :action => 'signup'})
        m.route_name("#{file_name}_register", "/#{controller_plural_name}/register", {:controller => controller_plural_name, :action => 'register'})
        m.route_name("#{file_name}_login",    "/#{controller_plural_name}/login",    {:controller => sessions_controller_controller_name, :action => 'new'})
        m.route_name("#{file_name}_logout",   "/#{controller_plural_name}/logout",   {:controller => sessions_controller_controller_name, :action => 'destroy'})
      end                     
    end
end
