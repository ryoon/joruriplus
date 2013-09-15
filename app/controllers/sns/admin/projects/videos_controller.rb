# encoding: utf-8
class Sns::Admin::Projects::VideosController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @project = Sns::Project.find(:first, :conditions=>{:code=>params[:parent]})
    return redirect_to sns_projects_path if @project.blank?
    return redirect_to sns_projects_path if @project.auth_check==false
    @project_code = @project.code
    @u_role = Core.user.has_auth?(:manager)
    @class = "meetingVideo"
  end

  def index
    @items = Sns::Video.where(:project_id => @project.id, :is_project=>1).desc(:created_at).paginate(:page => params[:page], :per_page => 20)
  end

  def show
    @item = Sns::Video.find(:first, :conditions=>{:_id => params[:id]})
    return redirect_to sns_project_photos_path(@project_code) if @item.blank?
  end

  def new
    @item = Sns::Video.new({:privacy=>"project", :created_user_id=>Core.profile.id, :is_project=>1, :project_id=>@project.id})
  end

  def create
    items = Sns::Video.any_in("_id"=>params[:ids])
    items.each do |file|
      file.update_attributes!(:privacy => params[:item][:privacy] , :caption=>params[:item][:caption])
    end
    flash[:notice]="ファイルを追加しました。"
    return redirect_to sns_project_photos_path(@project_code)
  end


  def edit
    @item = Sns::Video.find(:first, :conditions=>{:_id=>params[:id]})
  end

  def update
    @item = Sns::Video.find(:first, :conditions=>{:_id=>params[:id]})
    options={ :is_project=>1, :project_id=>@project.id}
    if @item.photo_data_save(params, :update,options)
      flash[:notice] = "プロフィールを編集しました。"
      return redirect_to sns_project_photo_path(@project_code,@item)
    else
      render :action=>:edit
    end
  end


  def destroy
    @item = Sns::Video.find(:first, :conditions=>{:_id=>params[:id]})
    @item.destroy
    return_uri = redirect_to sns_project_videos_path(@project_code)
    return redirect_to return_uri
  end
protected

  def select_layout
    layout = "admin/sns/project"
    layout
  end
end