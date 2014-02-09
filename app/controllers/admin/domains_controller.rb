class Admin::DomainsController < ApplicationController
  protect_from_forgery :except => [:index]
  before_filter :login_required

  # GET /domains
  # GET /domains.xml
  def index
    @myDomain = session[:domain]
    @domains = Domain.find_by_sql( ["SELECT * from `domains` WHERE `owner_domain_id` = ?", @myDomain.id ]  )

    puts "number of results: " + @domains.length.to_s

    @resultArray = []

    @domains.each do | domain |
      @domainObj = {}
      @domainObj["name"] = domain["nickname"];
      @domainObj["id"]   = domain["id"];
      @domainObj["owner"] = domain["owner_domain_id"];
      @resultArray << @domainObj;
    end


    @result = @resultArray.to_json

    if params[:callback]
      @result = params[:callback] + "(" + @result + ")"
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @resultArray }
      format.js   { render :js  => @result }
    end
  end

  # GET /domains/1
  # GET /domains/1.xml
  def show
    @domain = Domain.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @domain }
      format.js   {
        @result = { :name => @domain.nickname }.to_json()
        if params[:callback]
          @result = params[:callback] + "(" + @result + ")"
        end
        render :js  => @result
      }
    end
  end

  # GET /domains/new
  # GET /domains/new.xml
  def new
    @myDomain = session[:domain]
    @domain = Domain.new
    @domain.owner_domain_id = @myDomain.id

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @domain }
    end
  end

  # GET /domains/1/edit
  def edit
    @domain = Domain.find(params[:id])
  end

  # POST /domains
  # POST /domains.xml
  def create
    @domain = Domain.new(params[:domain])


    respond_to do |format|
      if @domain.save && DomainStyle.new({:domain_id => @domain.id, :style_id => 1, :app_alias => "application", :group_alias => "category", :set_alias => "set", :story_alias => "story", :logo => "/static/default_logo.png" } ).save
        format.html { redirect_to(admin_domains_url) }
        format.xml  { render :xml => @domain, :status => :created, :location => @domain }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @domain.errors, :status => :unprocessable_entity }
      end
    end


    #storyGroup = StorySet.new( {:name => "Default", :domain_id => @domain.id} )
    #storyGroup.save

  end

  # PUT /domains/1
  # PUT /domains/1.xml
  def update
    @domain = Domain.find(params[:id])

    respond_to do |format|
      if @domain.update_attributes(params[:domain])
        format.html { redirect_to(admin_domains_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @domain.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /domains/1
  # DELETE /domains/1.xml
  def destroy
    @domain = Domain.find(params[:id])
    @domain_style = DomainStyle.find_by_domain_id @domain.id
    @domain.destroy
    @domain_style.destroy

    respond_to do |format|
      format.html { redirect_to(admin_domains_url) }
      format.xml  { head :ok }
    end
  end
end
