class Scriptwords::UsersController < ScriptwordsController
  # GET /users
  # GET /users.xml
  def index
    @users = User.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html { render :layout => "scriptwords" }# show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.new

    respond_to do |format|
      format.html  { render :layout => 'scriptwords' }# new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.xml
  def create
    @user = User.new(params[:user])
    @user.group = Group.new
    @user.group.name = "Scriptwords"
    @user.bright_text_application_id = BrightTextApplication.where(:name=>"ScriptureWords").first.id
    @user.user_type = 0

    respond_to do |format|
      if @user.save
        GroupMember.where(:email => @user.email).update_all(:user_id=>@user.id)
        log_in! @user
        format.html { redirect_to(scriptwords_root_url, :notice => 'User was successfully created.') }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" , :layout => "scriptwords" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to(@user, :notice => 'User was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(scriptwords_users_url) }
      format.xml  { head :ok }
    end
  end

  def new_session
    reset_session
    @user = User.new
  end

  def authenticate
    @bt_application = BrightTextApplication.where(:name=>"ScriptureWords").first
    if (@user = User.authenticate_user params[:user][:email], params[:user][:password], @bt_application)
      #@user_apps = UserApp.where(:user_id=>@user.id, :bright_text_application_id=>BrightTextApplication.find_by_name("ApologyWiz").id)
      #if @user_apps.present?
        log_in! @user
        redirect_to scriptwords_stories_path, notice: "Logged in!"
      #else
        #redirect_to 'http://scriptwords.com'   
        #flash.now[:error] = 'In order to log in and create personal content, you must have the paid version of Apology Wiz! You can find it here:'
        #render 'unpaid.html.erb', :layout=>true
      #end
    else
      @user = User.new
      flash.now[:error] = "Email or password is invalid"
      render 'new_session', layout: "scriptwords"
    end
  end

  def destroy_session
    session[:domain] = nil
    session[:style] = nil
    reset_session
    redirect_to scriptwords_login_path
  end
end
