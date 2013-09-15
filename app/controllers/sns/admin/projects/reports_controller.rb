class Sns::Admin::Projects::ReportsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @project = Sns::Project.find(:first, :conditions=>{:code=>params[:parent]})
    return redirect_to sns_projects_path if @project.blank?
    return redirect_to sns_projects_path if @project.auth_check==false
    @project_code = @project.code
    @class = "activity"
    #@u_role = Core.user.has_auth?(:manager)
    @subfeed = "project"
    params[:subfeed] = "project"
    params[:project_id]=@project.id
    @is_project = {:project=>1}
    @fav = params[:fav] || "0"
  end

  def index
    @feeds = Sns::Post.project_report(@project.id,@fav).display_limit.desc(:sequence)
  end

  #tweet関連
  def show
    @item = Sns::Post.where(:_id=>params[:id]).first
    return http_error(404) if @item.blank?
    @feed_user = @item.created_user
  end

protected

  def select_layout
    layout = "admin/sns/project"
    layout
  end
end