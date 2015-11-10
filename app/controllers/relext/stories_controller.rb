class Relext::StoriesController < RelextController
  protect_from_forgery :except => [:index]
  before_filter :login_required
  
  
  class NotOwner < StandardError
  end
  
  rescue_from NotOwner, with: :not_owner
  
  def not_owner(exception)
    puts "Exception: #{exception.message}", current_user, request.remote_ip
    respond_to do |format|             
        format.js
    end
  end

  # GET /stories
  # GET /stories.xml
  def index
    @story = Story.new
    @group_member = GroupMember.new
    @user = User.find(session[:user_id]);
    @application = find_application

    stories_sql =
      #"SELECT stories.id as id, story_set_categories.id as category_id, concat(story_set_categories.name,'-',stories.name) as name, stories.public as public, stories.descriptor as descriptor, CASE WHEN stories.user_id = ? THEN 1 ELSE 0 END AS user_id FROM stories " + 
      "SELECT stories.id as id, story_set_categories.id as category_id, story_set_categories.name as name, stories.name as subtitle, stories.public as public, stories.descriptor as descriptor, CASE WHEN stories.user_id = ? THEN 1 ELSE 0 END AS user_id FROM stories " + 
      "INNER JOIN story_sets ON stories.story_set_id = story_sets.id "+
      "INNER JOIN story_set_categories ON story_sets.category_id = story_set_categories.id " +
      "WHERE stories.bright_text_application_id = ? " +
      "AND (stories.user_id = ? " +
      "OR stories.user_id IN (SELECT groups.user_id FROM groups INNER JOIN group_members ON groups.id = group_members.group_id " +
      "WHERE group_members.email = ? ) " +
      #"OR stories.public = TRUE" + 
      " ) " + 
      "ORDER BY story_set_categories.created_at ASC";
    @stories = Story.find_by_sql [stories_sql, @user.id, @application.id, @user.id, @user.email ]
    #@stories = ActiveRecord::Base.connection.execute [stories_sql, @application.id, @user.id, @user.email ]

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
    if !@story.public? || !@story.shared_with_me(session[:user_id])
      if @story.user_id != session[:user_id]        
        @story.errors.add(:user_id,"Sorry! You are not creator of this Word Slider")
        raise NotOwner
      end
    end
    
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
    if ( filter.present? && filter != "__unassigned" )
      @story.story_set_id = filter.to_i
    end
    respond_to do |format|
      format.html { render :layout => 'relext' }
      format.xml  { render :xml => @story }
    end
  end

  # GET /stories/XX/clone
  def clone
    @sourceStory = Story.find(params[:id])
    @story = @sourceStory.dup
    number_of_similar_named_stories = Story.where("story_set_id = ? AND name like ?", @sourceStory.story_set_id, @sourceStory.name + "%").count('id')
    @story.name = @story.name.partition("-")[0] + "-" + (number_of_similar_named_stories + 1).to_s
    respond_to do |format|
        format.html { render :action => "new" }        
    end
  end

  # GET /stories/1/edit
  def edit
    @story = Story.find(params[:id])
    if !@story.public? || !@story.shared_with_me(session[:user_id])
      if @story.user_id != session[:user_id]        
        @story.errors.add(:user_id,"Sorry! You are not creator of this Word Slider")
        raise NotOwner
      end
    end
  end

  # POST /stories
  # POST /stories.xml
  def create
	#create story set
    story_set = StorySet.new(name: "storyset#{StorySet.count + 1}")
    story_set.domain_id = session[:domain].id
    story_set.bright_text_application_id = session[:br_application_id]
    story_set.user_id = current_user.id
    #create story
    @story = Story.new(user_id: current_user.id, story_set: story_set, name: params[:story][:category], category: params[:story][:category], description: "", descriptor: "")
    #@story.name = "ScriptureWord#{Story.where(:user_id => current_user.id).count + 1}" if @story.name.blank?
    @story.domain_id = session[:domain].id
    @story.bright_text_application_id = session[:br_application_id]
    @story.user_id = session[:user_id]
    @story.story_authors.build().user_id = session[:user_id]
    #set category details
    @story.story_set.story_set_category.domain_id = session[:domain].id
    @story.story_set.story_set_category.application_id = session[:br_application_id]
    @story.story_set.story_set_category.user_id = current_user.id
    @story.rank = 0
    @story.brighttext = false

    respond_to do |format|
      if @story.save
        format.html { redirect_to @story, notice: 'Story was successfully created.' }
        format.xml  { render :xml => @story, :status => :created, :location => @story }
        format.json { render json: @story, status: :created}
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
    if !@story.shared_with_me(session[:user_id])
      if @story.user_id != session[:user_id]        
        @story.errors.add(:user_id,"Sorry! You are not creator of this Word Slider")
        raise NotOwner
      end
    end
    
    @story_author = StoryAuthor.where(:user_id=>session[:user_id], :story_id=>@story.id).first
    if(@story_author.nil?)
      @story.story_authors.build().user_id = session[:user_id]      
    end
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
    if @story.user_id != session[:user_id]        
      @story.errors.add(:user_id,"Sorry! You are not creator of this Word Slider")
      raise NotOwner
    end
    @story.destroy

    respond_to do |format|
      format.html { redirect_to("/relext/stories?filter=" + @story.story_set_id.to_s) }
      format.json{ render :json=> {:success => "true"} }
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
      redirect_to relext_stories_path
    elsif( params[:story_set_id] ==  "__unassigned")
      @stories = Story.where("story_set_id IS NULL AND domain_id = ?", session[:domain].id).order(:rank)
    else
      @stories = Story.where(:story_set_id => params[:story_set_id], :domain_id => session[:domain].id).order(:rank)
    end
  end

  def update_stories_rank
    #p params.to_yaml
    @stories = Story.update(params[:stories].keys, params[:stories].values)
    redirect_to relext_stories_path(:filter => params[:filter])
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
