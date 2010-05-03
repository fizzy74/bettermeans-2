class MotionsController < ApplicationController
  
  before_filter :find_project, :only => [:new,:index,:create,:show, :edit]
  before_filter :find_motion, :only => [:show, :edit, :destroy, :update, :reply]
  before_filter :check_visibility_permission, :only => [:show]
  before_filter :require_admin, :only => [:edit]
  
  # GET /motions
  # GET /motions.xml
  def index
    @motions = @project.motions.allactive

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @motions }
    end
  end

  # GET /motions/1
  # GET /motions/1.xml
  def show
    
    @topic = @motion.topic
    @board = @topic.board
    @replies = @topic.children.find(:all, :include => [:author, :attachments, {:board => :project}])
    @replies.reverse! if User.current.wants_comments_in_reverse_order?
    @reply = Message.new(:subject => "RE: #{@topic.subject}")
    

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @motion }
    end
  end

  # GET /motions/new
  # GET /motions/new.xml
  def new
    @motion = Motion.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @motion }
    end
  end

  # GET /motions/1/edit
  def edit
  end

  # POST /motions
  # POST /motions.xml
  def create
    @motion = Motion.new(params[:motion])
    @motion.project_id = @project.id
    @motion.state = Motion::STATE_ACTIVE
    @motion.set_values

    respond_to do |format|
      if @motion.save
        flash[:notice] = 'Motion was successfully created.'
        format.html { redirect_to :action => "index" }
        format.xml  { render :xml => @motion, :status => :created, :location => @motion }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @motion.errors, :status => :unprocessable_entity }
      end
    end
  end
  

  # PUT /motions/1
  # PUT /motions/1.xml
  def update
    
    respond_to do |format|
      if @motion.update_attributes(params[:motion])
        flash[:notice] = 'Motion was successfully updated.'
        format.html { redirect_to(@motion) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @motion.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /motions/1
  # DELETE /motions/1.xml
  def destroy
    @motion.destroy

    respond_to do |format|
      format.html { redirect_to(motions_url) }
      format.xml  { head :ok }
    end
  end
  
  # Reply to a motion discussion
  def reply
    @topic = @motion.topic
    @reply = Message.new(params[:reply])
    @reply.author = User.current
    @reply.board = @topic.board
    @topic.children << @reply
    if !@reply.new_record?
      attach_files(@reply, params[:attachments])
    end
    redirect_to :action => 'show', :id => @motion, :project_id => @motion.project_id
  rescue
    404
  end
  
  
  def find_project
    @project = Project.find(params[:project_id]).root
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_motion
    @motion = Motion.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  
  def check_visibility_permission
    if !User.current.allowed_to_see_motion?(@motion)
       render_403
       return false
    end
    return true
  end
  
end
