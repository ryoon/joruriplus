# -*- encoding: utf-8 -*-
class Sns::Admin::ProjectsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  layout :select_layout

  def pre_dispatch
    @class = "projectRoot"
  end

  def index
    if Core.user.has_auth?(:manager)
      @items = Sns::Project.word(params[:word]).desc(:updated_at).paginate(:page => params[:page], :per_page => 20)
    else
      @items = Sns::Project.where(:state=>"enabled").user_word(params[:word]).desc(:updated_at).paginate(:page => params[:page], :per_page => 20)
    end
  end

  def show
    return redirect_to sns_projects_path if params[:id].blank?
    @item = Sns::Project.find(:first, :conditions=>{:code=>params[:id]})
    return redirect_to sns_projects_path if @item.blank?
    return redirect_to sns_projects_path if @item.publish != "public" && @item.is_join? == false if !Core.user.has_auth?(:manager)
    @photos = []
    @files = []
    show_files(@item.contents)
    manager_ids = []
    manager_ids += @item.managers.map{|user| user.user_id}
    managers = @item.managers
    @managers = managers.sort{|a,b| a.user.sort_no.to_s <=> b.user.sort_no.to_s}
    if manager_ids.blank?
      members = @item.members
    else
      members = @item.members.where(:user_id.nin=>manager_ids)
    end
    @members = members.sort{|a,b| a.user.sort_no.to_s <=> b.user.sort_no.to_s}
    @already_submit = false
    if @item.publish=="public"
      proposals = Sns::FriendProposal.where({:fr_user_id=>Core.profile.id, :state.in=>["unread","read"], :kind=>"project_join", :project_id=>@item.id})
      @already_submit = true unless proposals.blank?
    end
  end

  def new
    return redirect_to "/_admin" unless Core.user.has_auth?(:manager)
    @item = Sns::Project.new({:created_user_id=>Core.profile.id, :state=>"enabled", :publish=>"public",:project_file_limit=>300, :post_file_limit=>10})
    @item.caption = "1、目的<br />2、概要"
  end

  def create
    @item = Sns::Project.new(params[:item])
    @item.contents = file_params(params)
    if @item.save
      file_update
      flash[:notice]="プロジェクトを作成しました。"
      return redirect_to new_sns_member_path(@item.code)
    else
      render :action=>:new
      return
    end
  end

  def edit
    @item = Sns::Project.find(params[:id])
    @item.project_file_limit = @item.project_file_limit_show
    @item.post_file_limit = @item.post_file_limit_show
    @project_code = @item.code
    @photos = []
    @files = []
    show_files(@item.contents)
    @project = @item
  end

  def update
    @item = Sns::Project.find(params[:id])
    @item.contents = file_params(params)
    @item.attributes = params[:item]
    file_update
    if @item.save
      flash[:notice] =  "プロジェクトを編集しました。"
      return redirect_to sns_project_path(@item.code)
    else
      render :action=>:edit
    end
  end

  def show_files(contents)
    contents.each do |f|
      if f[0]=="photo"
        photo_item = Sns::Photo.find(:first, :conditions=>{:_id=>f[1]})
        @photos << photo_item if photo_item
      elsif f[0]=="file"
        file_item = Sns::File.find(:first, :conditions=>{:_id=>f[1]})
        @files << file_item if file_item
      end
    end if contents
  end



  def file_params(params)
    contents = []
    if params[:photoids]
      @photos = Sns::Photo.any_in("_id"=>params[:photoids])
      @photos.each do |photo|
        contents<<["photo", photo.id]
      end if @photos
    end
    if params[:fileids]
      @files = Sns::File.any_in("_id"=>params[:fileids])
      @files.each do |file|
        contents << ["file", file.id]
      end if @files
    end
    return contents
  end

  def file_update
    p_album = Sns::Album.where(:kind=>"photo" , :project_id => @item.id).first
    if p_album
      p_a_id = p_album.id
    else
      new_p_album = Sns::Album.create(:kind=>"photo" , :project_id => @item.id, :name => "#{@item.title}のフォト")
      p_a_id = new_p_album.id
    end
    f_album = Sns::Album.where(:kind=>"file" , :project_id => @item.id).first
    if f_album
      f_a_id = f_album.id
    else
      new_f_album = Sns::Album.create(:kind=>"photo" , :project_id => @item.id, :name => "#{@item.title}のファイル")
      f_a_id = new_f_album.id
    end
    @photos.each do |photo|
      photo.update_attributes!(:privacy => "public", :project_id=>@item.id, :is_project=>1, :album_id=>p_a_id  )
    end if @photos
    @files.each do |file|
      file.update_attributes!(:privacy => "public" , :project_id=>@item.id, :is_project=>1, :album_id=>f_a_id )
    end if @files
  end

  def destroy
    @item = Sns::Project.find(:first, :conditions=>{:_id=>params[:id]})
    @item.destroy
    flash[:notice] =  "プロジェクトを削除しました。"
    return redirect_to sns_projects_path
  end


protected

  def select_layout
    layout = "admin/sns/project"
    layout
  end
end
