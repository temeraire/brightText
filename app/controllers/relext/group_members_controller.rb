require 'rexml/document'
class Relext::GroupMembersController < RelextController
  protect_from_forgery :except => [:index]
  before_filter :login_required
  # GET /story_categories
  # GET /story_categories.xml
  def index
    @group = Group.find_by_user_id(session[:user_id])
    puts @group.id
    @group_members  = GroupMember.where(:group_id=>@group.id)
    respond_to do |format|
      format.json {render :json=> { :success => "true", :group_members => @group_members } }
      format.html # index.html.erb
      format.xml  { render :xml => @group_members }
    end
  end

  # GET /story_categories/1
  # GET /story_categories/1.xml
  def show
    @group_member = GroupMember.find(params[:id])
    raise ' not owner ' unless @group_member.user_id == session[:user_id]
    respond_to do |format|
      format.html # show.html.erb
      format.xml  {
        render :xml => @group_member
      }
    end
  end

  # GET /story_categories/new
  # GET /story_categories/new.xml
  def new
    @group_member = GroupMember.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @group_member }
    end
  end

  # GET /story_categories/1/edit
  def edit
    @group_member = GroupMember.find(params[:id])
    raise ' not owner ' unless @group_member.user_id == session[:user_id]
  end

  # POST /story_categories
  # POST /story_categories.xml
  def create
    @group_member = GroupMember.new(params[:group_member])

    @user = User.find_by_email(@group_member.email)
    @group_member.user_id = @user.id if @user.present?
    @owner = User.find(session[:user_id])
    @group_member.group_id = @owner.group.id
    if @user.present?
      SharingMailer.invitation_registered(@owner, @user).deliver
    else
      SharingMailer.invitation(@owner.email, @group_member.email).deliver
    end
    
self
    respond_to do |format|
      if @group_member.save
        format.html { redirect_to('/relext/stories#step_3') }
        format.xml  { render :xml => @group_member, :status => :created, :location => @group_member }
        format.js
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @group_member.errors, :status => :unprocessable_entity }
        format.js
      end
    end
  end

  # PUT /story_categories/1
  # PUT /story_categories/1.xml
  def update
    @group_member = StorySetCategory.find(params[:id])
    raise ' not owner ' unless @group_member.domain_id == session[:domain].id
    respond_to do |format|
      if @group_member.update_attributes(params[:story_set_category])
        format.html { redirect_to('/relext/story_set_categories?filter=' + @group_member.application_id.to_s) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @group_member.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /story_categories/1
  # DELETE /story_categories/1.xml
  def destroy
    @group_member = GroupMember.find(params[:id])
    # @filter = @story_set_category.application_id.to_s
    # if ( @filter.blank? || @filter == "0")
    # @filter = ""
    # end

    # raise ' not owner ' unless @group_member.domain_id == session[:domain].id
    @group_member.destroy

    respond_to do |format|
      format.json {render :json=> { :success => "true" } }
      format.html { redirect_to relext_story_set_categories_path(:filter => @group_member.application_id.to_s) }
      format.xml  { head :ok }
    end
  end
end
