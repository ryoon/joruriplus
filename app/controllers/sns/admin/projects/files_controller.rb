# encoding: utf-8
class Sns::Admin::Projects::FilesController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @project = Sns::Project.find(:first, :conditions=>{:code=>params[:parent]})
    return redirect_to sns_projects_path if @project.blank?
    return redirect_to sns_projects_path if @project.auth_check==false
    @project_code = @project.code
    @u_role = Core.user.has_auth?(:manager)
    @class = "meetingFile"
  end

  def index
    @items = Sns::File.where(:project_id => @project.id, :is_project=>1).desc(:created_at).paginate(:page => params[:page], :per_page => 20)
  end

  def show
    @item = Sns::File.find(:first, :conditions=>{:_id=>params[:id]})
  end

  def new
    @item = Sns::File.new({:privacy=>"public", :created_user_id=>Core.profile.id, :is_project=>1, :project_id=>@project.id})
    @item.created_user_id = Core.profile.id
  end

  def create
    @item = Sns::File.new
    items = Sns::File.any_in("_id"=>params[:ids])
    items.each do |file|
      file.update_attributes!(:privacy => params[:item][:privacy], :caption=>params[:item][:caption])
    end
    flash[:notice]="ファイルを追加しました。"
    return redirect_to sns_project_files_path(@project_code)
  end


  def edit
    @item = Sns::File.find(:first, :conditions=>{:_id=>params[:id]})
  end

  def update
    @item = Sns::File.find(:first, :conditions=>{:_id=>params[:id]})
    options={ :is_project=>1, :project_id=>@project.id}
    if @item.file_data_save(params, :update, options)
      flash[:notice]="ファイルを追加しました。"
      return redirect_to sns_project_file_path(@project_code,@item)
    else
      flash[:notice]="ファイルの追加に失敗しました。"
      return redirect_to :action => 'edit'
    end
  end


  def destroy
    @item = Sns::File.find(:first, :conditions=>{:_id=>params[:id]})
    @item.destroy
    return redirect_to sns_project_files_path(@project_code)
  end

protected

  def select_layout
    layout = "admin/sns/project"
    layout
  end

end
