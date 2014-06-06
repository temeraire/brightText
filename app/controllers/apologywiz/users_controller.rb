class Apologywiz::UsersController < ApologywizController
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
      format.html { render :layout => "apologywiz" }# show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.new

    respond_to do |format|
      format.html  { render :layout => 'apologywiz' }# new.html.erb
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
    @user.group.name = "Apologies"
    @user.customer!

    respond_to do |format|
      if @user.save
        GroupMember.where(:email => @user.email).update_all(:user_id=>@user.id)
        log_in! @user
        format.html { redirect_to(apologywiz_root_url, :notice => 'User was successfully created.') }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" , :layout => "apologywiz" }
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
      format.html { redirect_to(apologywiz_users_url) }
      format.xml  { head :ok }
    end
  end

  def new_session
    reset_session
    @user = User.new
  end

  def authenticate
    if (@user = User.authenticate params[:user][:email], params[:user][:password])
      @user_apps = UserApp.where(:user_id=>@user.id, :bright_text_application_id=>BrightTextApplication.find_by_name("ApologyWiz").id)
      if @user_apps.present?
        log_in! @user
        redirect_to apologywiz_stories_path, notice: "Logged in!"
      else
        #redirect_to 'http://apologywiz.com'   
        flash.now[:error] = 'In order to register and log in, you must have the paid version of Apology Wiz! You can find it here:'
        render 'unpaid.html.erb', :layout=>true
      end
    else
      @user = User.new
      flash.now[:error] = "Email or password is invalid"
      render 'new_session', layout: "apologywiz"
    end
  end

  def destroy_session
    session[:domain] = nil
    session[:style] = nil
    reset_session
    redirect_to apologywiz_login_path
  end
end
