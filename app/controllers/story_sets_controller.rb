class StorySetsController < ApplicationController
  # GET /story_sets
  # GET /story_sets.xml
  def index
    @filter = request[:filter]
    @filter = "" if @filter == nil

    queryAndParts = ["domain_id = ?"]
    queryParams   = [session[:domain].id ]

    if ( @filter.empty? != true  && @filter != "__none")
      if @filter == "__unassigned"
        queryAndParts << "category_id IS NULL"
      else
        queryAndParts << "category_id = ?"
      queryParams   << @filter
      end
    end

    @story_sets = StorySet.find_by_sql ["select * from story_sets where " + queryAndParts.join(" AND ") + " order by rank asc", queryParams].flatten
    @categories = StorySetCategory.find_by_sql [ "select * from story_set_categories where domain_id = ?", session[:domain].id ]

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
    if ( filter != nil && filter != "__unassigned" )
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
    #debugger
    respond_to do |format|
      if @story_set.save
        clone_stories(params[:stories], @story_set.id) unless params[:stories].blank?
        format.html { redirect_to("/story_sets?filter=" + @story_set.category_id.to_s ) }
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
        format.html { redirect_to("/story_sets?filter=" + @story_set.category_id.to_s) }
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
      format.html { redirect_to("/story_sets?filter=" + @story_set.category_id.to_s) }
      format.xml  { head :ok }
    end
  end

  def clone
    @stories_set_original = StorySet.find(params[:id])
    @story_set = @stories_set_original.clone
    number_similar_named_storysets = StorySet.count(:conditions => ["name like ?", @story_set.name + "%"])
    @story_set.name = @story_set.name + "-" + (number_similar_named_storysets + 1).to_s    
    @stories = @stories_set_original.stories
    #debugger
    respond_to do |format|
      format.html { render :action => "new" }
    end
  end
  
  def reorder_story_sets_rank
    if( params[:category_id].blank? )
      redirect_to story_sets_path
    elsif( params[:category_id] ==  "__unassigned")
      @story_sets = StorySet.where("category_id IS NULL AND domain_id = ?", session[:domain].id).order(:rank)
    else
      @story_sets = StorySet.where(:category_id => params[:category_id], :domain_id => session[:domain].id).order(:rank)
    end
  end
  
  def update_story_sets_rank
    p params.to_yaml
    StorySet.update(params[:story_sets].keys, params[:story_sets].values)
    redirect_to story_sets_path(:filter => params[:filter])
  end
  
  private
  def clone_stories(story_ids, story_set_id)
    story_ids.each do |id|
      story = Story.find(id).clone
      story.story_set_id = story_set_id
      story.save
    end
  end
end
