# encoding: utf-8
class Sns::Admin::SearchesController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @cl = params[:cl] || "all"
    @seq = params[:date] || ""
    @limit = 5
    @limit = 10 if @cl != "all"
    @word = params[:keyword]
    @page = params[:page]
  end

  def index
    @prof_friend = Core.profile.get_friend_info
    @p_ids = Core.profile.project_select
    unless @word.blank?
      case @cl
        when "feed"
          feed_index(params)
        when "user"
          user_index(params)
        when "project"
          project_index(params)
        when "thread"
          thread_index(params)
        when "activity"
          activity_index(params)
        else
          feed_index(params)
          user_index(params)
          project_index(params)
          thread_index(params)
          activity_index(params)
      end
    end
    respond_to do |format|
      format.html {}
      format.xml {}
      format.js   {render :layout=>false }
    end
  end

  def feed_index(params)
    @feeds = Sns::Post.word_query(@word,@prof_friend[1], @p_ids,{:show_pubic=>1}).desc(:sequence).paginate(:page => @page, :per_page => @limit)
    @date_str = @feeds.last.sequence unless @feeds.blank?
  end

  def user_index(params)
    @my_friend = Sns::Friend.find(:first, :conditions=>{:user_id => Core.profile.id})
    if @cl=="user"
      @users = Sns::Profile.word_query(@word).order_by([[:sort_no, :asc]]).paginate(:page => @page, :per_page => @limit)
    else
      @users = Sns::Profile.word_query(@word).order_by([[:sort_no, :asc]]).limit(5)
    end
  end

  def project_index(params)
    if Core.user.has_auth?(:manager)
      @projects = Sns::Project.word(@word).desc(:updated_at).paginate(:page => @page, :per_page => @limit)
    else
      @projects = Sns::Project.where(:state=>"enabled").any_of({"members.user_id" => Core.profile.id}, {:publish=>"public"}).word(@word).desc(:updated_at).paginate(:page => @page, :per_page => @limit)
    end
  end

  def thread_index(params)
    @threads = Sns::Thread.word_query(@word,@p_ids).desc(:last_updated_at).paginate(:page => @page, :per_page => @limit)
  end

  def activity_index(params)
    @activities = Sns::Post.word_query_activity(@word,@p_ids).desc(:sequence).paginate(:page => @page, :per_page => @limit)
    @date_str = @activities.last.sequence unless @activities.blank?
  end

  def note_index(params)
  end

  def show
    redirect_path = sns_searches_path({:cl=>@cl,:word=>@word})
    if @cl=="thread"
      @item = Sns::Thread.where(:_id=>params[:id]).first
      unless @item.blank?
        @project  = @item.project
        if @project.blank?
          flash[:notice]="プロジェクトが削除されています。"
        else
          if @item.kind=="thread"
            redirect_path = sns_conference_path(@project.code,@item)
          else
            redirect_path = sns_conference_path(@project.code,@item.parent_id)
          end
        end
      end
    elsif @cl=="activity"
      @item = Sns::Post.where(:_id=>params[:id]).first
      unless @item.blank?
        @project  = @item.project
        if @project.blank?
          flash[:notice]="プロジェクトが削除されています。"
        else
          redirect_path = sns_report_path(@project.code,@item)
        end
      end
    elsif @cl=="feed"
      @item = Sns::Post.where(:_id=>params[:id]).first
      redirect_path = sns_post_path(@item) if @item
    end
    return redirect_to redirect_path
  end

protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end

end
