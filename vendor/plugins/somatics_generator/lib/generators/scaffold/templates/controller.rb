class <%= controller_class_name %>Controller < ApplicationController
  <% if options[:authenticated] %>
  # Be sure to include AuthenticationSystem in Application Controller instead
  include <%= class_name %>AuthenticatedSystem
  <% end -%>

  layout Proc.new { |c| c.request.format.js? ? false : :application }
  
  # GET /<%= table_name %>
  # GET /<%= table_name %>.xml
  def index
    respond_to do |format|
      format.html {
        @<%= table_name %> = <%= class_name %>.all(:order => (params[:sort].gsub('_reverse', ' DESC') unless params[:sort].blank?)).paginate(:page => params[:page])        
      }
      format.xml  { 
        @<%= table_name %> = <%= class_name %>.all
        render :xml => @<%= table_name %>
      }
      format.xls  {
        @<%= table_name %> = <%= class_name %>.all
        render :xls => @<%= table_name %>
      }
    end
  end

  # GET /<%= table_name %>/1
  # GET /<%= table_name %>/1.xml
  def show
    @<%= file_name %> = <%= class_name %>.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @<%= file_name %> }
    end
  end

  # GET /<%= table_name %>/new
  # GET /<%= table_name %>/new.xml
  def new
    @<%= file_name %> = <%= class_name %>.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @<%= file_name %> }
    end
  end

  # GET /<%= table_name %>/1/edit
  def edit
    @<%= file_name %> = <%= class_name %>.find(params[:id])
  end

  # POST /<%= table_name %>
  # POST /<%= table_name %>.xml
  def create
    @<%= file_name %> = <%= class_name %>.new(params[:<%= file_name %>])

    respond_to do |format|
      if @<%= file_name %>.save
        flash[:notice] = '<%= class_name %> was successfully created.'
        format.html { redirect_to(@<%= file_name %>) }
        format.xml  { render :xml => @<%= file_name %>, :status => :created, :location => @<%= file_name %> }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @<%= file_name %>.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /<%= table_name %>/1
  # PUT /<%= table_name %>/1.xml
  def update
    @<%= file_name %> = <%= class_name %>.find(params[:id])

    respond_to do |format|
      if @<%= file_name %>.update_attributes(params[:<%= file_name %>])
        flash[:notice] = '<%= class_name %> was successfully updated.'
        format.html { redirect_to(@<%= file_name %>) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @<%= file_name %>.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /<%= table_name %>/1
  # DELETE /<%= table_name %>/1.xml
  def destroy
    @<%= file_name %> = <%= class_name %>.find(params[:id])
    @<%= file_name %>.destroy

    respond_to do |format|
      format.html { redirect_to(<%= table_name %>_url) }
      format.xml  { head :ok }
    end
  end
  
  <% if options[:authenticated] -%>
    def signup
      @<%= file_name %> = <%= class_name %>.new
    end

    def register
      <%= file_name %>_logout_keeping_session!
      @<%= file_name %> = <%= class_name %>.new(params[:<%= file_name %>])
  <% if options[:stateful] -%>
      @<%= file_name %>.register! if @<%= file_name %> && @<%= file_name %>.valid?
      success = @<%= file_name %> && @<%= file_name %>.valid?
  <% else -%>
      success = @<%= file_name %> && @<%= file_name %>.save
  <% end -%>
      if success && @<%= file_name %>.errors.empty?
        <% if !options[:include_activation] -%>
        # Protects against session fixation attacks, causes request forgery
        # protection if visitor resubmits an earlier form using back
        # button. Uncomment if you understand the tradeoffs.
        # reset session
        self.current_<%= file_name %> = @<%= file_name %> # !! now logged in
        <% end -%>redirect_back_or_default('/')
        flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
      else
        flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
        render :action => 'signup'
      end
    end
  <% if options[:include_activation] %>
    def activate
      <%= file_name %>_logout_keeping_session!
      <%= file_name %> = <%= class_name %>.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
      case
      when (!params[:activation_code].blank?) && <%= file_name %> && !<%= file_name %>.active?
        <%= file_name %>.activate!
        flash[:notice] = "Signup complete! Please sign in to continue."
        redirect_to "/#{controller_plural_name}/login"
      when params[:activation_code].blank?
        flash[:error] = "The activation code was missing.  Please follow the URL from your email."
        redirect_back_or_default('/')
      else 
        flash[:error]  = "We couldn't find a <%= file_name %> with that activation code -- check your email? Or maybe you've already activated -- try signing in."
        redirect_back_or_default('/')
      end
    end
  <% end -%>  
    <% end -%>
end
