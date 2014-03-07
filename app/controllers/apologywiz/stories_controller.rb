class Apologywiz::StoriesController < ApologywizController
  protect_from_forgery :except => [:index]
  before_filter :login_required

  # GET /stories
  # GET /stories.xml
  def index
    @story = Story.new
    @highlighted_phreses = params[:q]
    @filter = request[:filter]

    @application = find_application

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
      @stories = Story.find_all_by_user_id(session[:user_id])
    end

    session[:br_story_set_id] = @story_set.id unless @story_set.blank?
    @filter = @story_set.id.to_s if @filter.blank? && !@story_set.blank? #update @filter for selection list and breadcrumbs similar values
    if not params[:q].blank?
      @stories = @stories.search_for params[:q]
      @highlighted_phreses = params[:q].split()
    end

    respond_to do |format|
      format.json {render :json=> { :success => "true", :stories => @stories } }
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
      format.html { render :layout => 'apologywiz' }
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
    story_set = StorySet.new(name: "storyset#{StorySet.count + 1}")
    story_set.domain_id = session[:domain].id
    @story = Story.new(user_id: current_user.id, story_set: story_set, name: params[:story][:name], category: params[:story][:category], description: params[:story][:description])
    #@story.rank = 1 + Story.maximum(:rank, :conditions => ["story_set_id = ?", @story.story_set_id])
    @story.domain_id = session[:domain].id
    @story.story_set.story_set_category.domain_id = session[:domain].id
    @story.story_set.story_set_category.application_id = session[:br_application_id]
    @story.rank = 0

    respond_to do |format|
      if @story.save
        format.json{ render :json=> {:success => "true", :story_id => @story.id } }
        format.html { redirect_to(root_path, :notice => 'Story was successfully created.') }
        format.xml  { render :xml => @story, :status => :created, :location => @story }
      else
        #debugger
        format.json{ render :json=> @story.errors }
        format.html { render :action => "new" }
        format.xml  { render :xml => @story.errors, :status => :unprocessable_entity }
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
        format.json{ render :json=> {:success => "true"} }
        format.html { redirect_to("/apologywiz/stories?filter=" + @story.story_set_id.to_s, :notice => 'Story was successfully updated.') }
        format.xml  { head :ok }
      else
        logger.debug "#{@story}"
        format.json{ render :json=> {:success => "false"} }
        format.html { render :action => "edit" }
        format.xml  { render :xml => @story.errors, :status => :unprocessable_entity }
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
      format.html { redirect_to("/apologywiz/stories?filter=" + @story.story_set_id.to_s) }
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
      redirect_to apologywiz_stories_path
    elsif( params[:story_set_id] ==  "__unassigned")
      @stories = Story.where("story_set_id IS NULL AND domain_id = ?", session[:domain].id).order(:rank)
    else
      @stories = Story.where(:story_set_id => params[:story_set_id], :domain_id => session[:domain].id).order(:rank)
    end
  end

  def update_stories_rank
    #p params.to_yaml
    @stories = Story.update(params[:stories].keys, params[:stories].values)
    redirect_to apologywiz_stories_path(:filter => params[:filter])
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
