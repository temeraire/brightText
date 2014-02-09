class Admin::DomainStylesController < ApplicationController
  protect_from_forgery :except => [:index]
  before_filter :login_required
  # GET /domain_styles/1/edit
  def edit
    @domain_style = DomainStyle.find(params[:id])
    @domain       = Domain.find( @domain_style.domain_id )
  end

  def new
    @domain_style = DomainStyle.new
  end


  # PUT /domain_styles/1
  # PUT /domain_styles/1.xml
  def update
    @domain_style = DomainStyle.find(params[:id])

    respond_to do |format|
      if @domain_style.update_attributes(params[:domain_style])
        format.html { redirect_to("/admin/domains", :notice => 'Domain style was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @domain_style.errors, :status => :unprocessable_entity }
      end
    end
  end
end
