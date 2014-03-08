class Admin::StoriesController < ApplicationController
  protect_from_forgery :except => [:index]
  before_filter :login_required

  # GET /stories
  # GET /stories.xml
  def index
    @highlighted_phreses = params[:q]
    @filter = request[:filter]
    session[:filter] = @filter

    @application = find_application

#    if @filter == "__none"
#      @stories = Story.where("domain_id = ? AND story_set_id is NULL",session[:domain].id).order(:name)
#    els

    if @filter == "__unassigned"
      @stories = Story.where("domain_id = ? AND story_set_id is NULL",session[:domain].id).order(:name)
    else
      @story_set = StorySet.find_by_id @filter
      if @story_set.blank?
        @application = find_application
        @category = find_category_for @application
        unless @category.blank?
          #debugger
          @story_sets = @category.story_sets.order(:name)
          @story_set = @story_sets.find_by_id session[:br_story_set_id]
          @story_set = @story_sets.first if @story_set.blank?
        end
      else
        @category = @story_set.story_set_category
        @application = @category.bright_text_application unless @category.blank?
        @story_sets = @category.story_sets.order(:name) unless @category.blank?
      end

      if @story_set.nil?
        @stories = Story.where("stories.domain_id" => session[:domain].id);
      else
          if @story_set.category_id.nil?
            @stories = Story.joins(:story_set).where(
                      {"stories.domain_id" => session[:domain].id}.merge(
                          @filter == "__none" ? {} : {"stories.story_set_id" => @story_set})).order(:name)
          else
            @stories = Story.joins(:story_set => {:story_set_category => :bright_text_application}).where(
                      {"stories.domain_id" => session[:domain].id,
                      "bright_text_applications.id" => @application,
                      "story_set_categories.id" => @category}.merge(
                          @filter == "__none" ? {} : {"stories.story_set_id" => @story_set})).order(:name)
          end
      end
      session[:br_story_set_id] = @story_set.id unless @story_set.blank?
      @filter = @story_set.id.to_s if @filter.blank? && !@story_set.blank? #update @filter for selection list and bread crumbs similar values

    end

    if not params[:q].blank?
      @stories = Story.where("stories.domain_id" => session[:domain].id);
      @stories = @stories.search_for params[:q]
      @highlighted_phreses = params[:q].split()
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @stories }
    end
  end

  # GET /stories/1
  # GET /stories/1.xml
  def show
    @story = Story.find(params[:id])
    raise ' not owner ' unless @story.domain_id == session[:domain].id
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @story }
      format.js   { render :js => request[:callback] + "(" + @story.descriptor + ")" }
    end
  end

  # GET /stories/new
  # GET /stories/new.xml
  def new
    @story = Story.new
    filter = params[:filter]
    if ( filter != nil && filter != "__unassigned" )
      @story.story_set_id = filter.to_i
    end
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @story }
    end
  end

  # GET /stories/XX/clone
  def clone
    @sourceStory = Story.find(params[:id])
    @story = @sourceStory.clone
    number_of_similar_named_stories = Story.count(:conditions => ["story_set_id = ? AND name like ?", @sourceStory.story_set_id, @sourceStory.name + "%"])
    @story.name = @story.name + "-" + (number_of_similar_named_stories + 1).to_s
    respond_to do |format|
        format.html { render :action => "new" }
    end
  end

  # GET /stories/1/edit
  def edit
    @story = Story.find(params[:id])
    raise ' not owner ' unless @story.domain_id == session[:domain].id
  end

  # POST /stories
  # POST /stories.xml
  def create
    @story = Story.new(params[:story])
    #@story.rank = 1 + Story.maximum(:rank, :conditions => ["story_set_id = ?", @story.story_set_id])
    @story.domain_id = session[:domain].id
    @story.rank = 0

    respond_to do |format|
      if @story.save
        format.html { redirect_to @story, notice: 'Story was successfully created.' }
        format.xml  { render :xml => @story, :status => :created, :location => @story }
        format.json { render json: @story, status: :created, location: @story }
        format.js
      else
        #debugger
        format.json{ render :json=> @story.errors }
#        format.html { render :action => "new" }
        format.xml  { render :xml => @story.errors, :status => :unprocessable_entity }
        format.js
      end
    end


  end

  # PUT /stories/1
  # PUT /stories/1.xml
  def update
    @story = Story.find(params[:id])
    raise ' not owner ' unless @story.domain_id == session[:domain].id
    respond_to do |format|
      if @story.update_attributes(params[:story])
        format.html { redirect_to @story, notice: 'Story was successfully created.' }
        format.xml  { render :xml => @story, :status => :updated, :location => @story }
        format.json { render json: @story, status: :updated, location: @story }
        format.js
      else
        logger.debug "#{@story}"
        format.json{ render :json=> {:success => "false"} }
        format.html { render :action => "edit" }
        format.xml  { render :xml => @story.errors, :status => :unprocessable_entity }
        format.js
      end
    end
  end

  # DELETE /stories/1
  # DELETE /stories/1.xml
  def destroy
    @story = Story.find(params[:id])
    raise ' not owner ' unless @story.domain_id == session[:domain].id
    @story.destroy

    respond_to do |format|
      format.html { redirect_to("/admin/stories?filter=" + @story.story_set_id.to_s) }
      format.xml  { head :ok }
    end
  end

  def rank
    @story = Story.find(params[:story][:id])
    @story.rank =  params[:story][:rank]
    @story.save!
  end

  def legacyxml
    @story = Story.find(params[:id])

    #invoke the save proxy to get xml
    result = REXML::Document.new("<Story/>")
    result.root.attributes["id"]   = @story.id
    result.root.attributes["name"] = @story.name
    @story.toXml( result.root )

    #return the xml
    render :xml => result
  end

  def clonesxml
    @story = Story.find(params[:id])
    setid = @story.story_set_id

    result = REXML::Document.new("<RelatedStories/>")
    if ( setid )
      stories = Story.find_by_sql [ "select id from stories where story_set_id = ? and id <> ?", setid, @story.id ];
      stories.each do | story |
        storiesEl = result.root.add_element("StoryId")
        storiesEl.text = story.id.to_s
      end
    end
    render :xml => result
  end

  def reorder_stories_rank
    if( params[:story_set_id].blank? )
      redirect_to admin_stories_path
    elsif( params[:story_set_id] ==  "__unassigned")
      @stories = Story.where("story_set_id IS NULL AND domain_id = ?", session[:domain].id).order(:rank)
    else
      @stories = Story.where(:story_set_id => params[:story_set_id], :domain_id => session[:domain].id).order(:rank)
    end
  end

  def update_stories_rank
    #p params.to_yaml
    @stories = Story.update(params[:stories].keys, params[:stories].values)
    redirect_to admin_stories_path(:filter => params[:filter])
  end

  private
  def find_category_for(application)
    if application.instance_of? BrightTextApplication
      category = application.story_set_categories.find_by_id session[:br_category_id]
      category = application.story_set_categories.first if category.blank?
    end
    category
  end

end
