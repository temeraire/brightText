class Relext::StorySetsController < RelextController
  protect_from_forgery :except => [:index]
  before_filter :login_required

  # GET /story_sets
  # GET /story_sets.xml
  def index
    @filter = request[:filter]
    @category = StorySetCategory.find_by_id @filter
    if @category.blank?
      @application = find_application

      unless @application.blank?
        @categories = @application.story_set_categories.order(:name)
        @category = @categories.find_by_id session[:br_category_id]
        @category = @categories.first if @category.blank?
      end
    else
      @application = @category.bright_text_application
      @categories = @application.story_set_categories.order(:name) unless @application.blank?
    end

    session[:br_category_id] = @category.id unless @category.blank?

    if @filter == "__unassigned"
      @story_sets = StorySet.where("domain_id = ? AND category_id is NULL",session[:domain].id).order(:name)
    else
      if @category.present? && @category.application_id.blank?
        @story_sets = StorySet.joins(:story_set_category).where(
                      {"story_sets.domain_id" => session[:domain].id}.merge(
                           @filter == "__none" ? {} : {"story_sets.category_id" => @category})).order(:name)
      elsif
      @story_sets = StorySet.joins(:story_set_category => :bright_text_application).where(
                      {"story_sets.domain_id" => session[:domain].id,
                       "bright_text_applications.id" => @application}.merge(
                           @filter == "__none" ? {} : {"story_sets.category_id" => @category})).order(:name)
      end
    end

    @filter = @category.id.to_s if @filter.blank? && !@category.blank? #update @filter for selection list and breadcrumbs similar values

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @story_sets }
    end
  end

  # GET /story_sets/1
  # GET /story_sets/1.xml
  def show
    @story_set = StorySet.find(params[:id])
    raise ' not owner ' unless @story_set.domain_id == session[:domain].id
    respond_to do |format|
      format.html # show.html.erb
      format.xml  {
        result = REXML::Document.new("<StorySet/>")
        stories = result.root.add_element("Stories")
        storyEntries = Story.find_by_sql ["select * from stories where story_set_id = ?", @story_set.id ]
        storyEntries.each do | storyEntry |
          story = stories.add_element("Story")
          story.attributes["id"] = storyEntry.id
        end

        render :xml => result
      }
    end
  end

  # GET /story_sets/new
  # GET /story_sets/new.xml
  def new
    @story_set = StorySet.new
    filter = params[:filter]
    if ( filter.present? && filter != "__unassigned" )
    @story_set.category_id = filter.to_i

    end
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @story_set }
    end
  end

  # GET /story_sets/1/edit
  def edit
    @story_set = StorySet.find(params[:id])
    raise ' not owner ' unless @story_set.domain_id == session[:domain].id
  end

  # POST /story_sets
  # POST /story_sets.xml
  def create
    @story_set = StorySet.new(params[:story_set])
    @story_set.domain_id = session[:domain].id
    @story_set.user_id = session[:user_id]
    @story_set.bright_text_application_id = session[:br_application_id]
    #debugger
    respond_to do |format|
      if @story_set.save
        clone_stories(params[:stories], @story_set.id) unless params[:stories].blank?
        format.html { redirect_to("/relext/story_sets?filter=" + @story_set.category_id.to_s ) }
        format.xml  { render :xml => @story_set, :status => :created, :location => @story_set }
      else
        format.html {
          unless params[:original_story_set].blank?
            @stories_set_original = StorySet.find(params[:original_story_set])
            @stories = @stories_set_original.stories
          end
          render :action => "new"
        }
        format.xml  { render :xml => @story_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /story_sets/1
  # PUT /story_sets/1.xml
  def update
    @story_set = StorySet.find(params[:id])
    raise ' not owner ' unless @story_set.domain_id == session[:domain].id
    respond_to do |format|
      if @story_set.update_attributes(params[:story_set])
        format.html { redirect_to("/relext/story_sets?filter=" + @story_set.category_id.to_s) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @story_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /story_sets/1
  # DELETE /story_sets/1.xml
  def destroy
    @story_set = StorySet.find(params[:id])
    raise ' not owner ' unless @story_set.domain_id == session[:domain].id
    @story_set.destroy

    respond_to do |format|
      format.html { redirect_to relext_story_sets_path(:filter => @story_set.category_id.to_s) }
      format.xml  { head :ok }
    end
  end

  def clone
    @stories_set_original = StorySet.find(params[:id])
    @story_set = @stories_set_original.dup
    number_similar_named_storysets = StorySet.where("category_id = ? AND name like ?",@stories_set_original.category_id, @story_set.name + "%").count('id');
    @story_set.name = @story_set.name.partition("-")[0] + "-" + (number_similar_named_storysets + 1).to_s
    @stories = @stories_set_original.stories
    #debugger
    respond_to do |format|
      format.html { render :action => "new" }
    end
  end

  def reorder_story_sets_rank
    if( params[:category_id].blank? )
      redirect_to relext_story_sets_path
    elsif( params[:category_id] ==  "__unassigned")
      @story_sets = StorySet.where("category_id IS NULL AND domain_id = ?", session[:domain].id).order(:rank)
    else
      @story_sets = StorySet.where(:category_id => params[:category_id], :domain_id => session[:domain].id).order(:rank)
    end
  end

  def update_story_sets_rank
    p params.to_yaml
    StorySet.update(params[:story_sets].keys, params[:story_sets].values)
    redirect_to relext_story_sets_path(:filter => params[:filter])
  end
end
