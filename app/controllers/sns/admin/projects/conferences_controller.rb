# -*- encoding: utf-8 -*-
class Sns::Admin::Projects::ConferencesController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @project = Sns::Project.find(:first, :conditions=>{:code=>params[:parent]})
    return redirect_to sns_projects_path if @project.blank?
    return redirect_to sns_projects_path if @project.auth_check==false
    @project_code = @project.code
    @class = "meetingRoom"
    @fav = params[:fav] || "0"
  end

  def index
    @threads = Sns::Thread.show_titles(@project.id,@fav).desc(:conf_sequence).paginate(:page => params[:page], :per_page => 10)
    @thread = Sns::Thread.new({:project_id=>@project.id, :project_sequence=>@project.sequence, :created_user_id=>Core.profile.id})

    @thread_titles = @threads.sort{|a,b| a.conf_sequence <=> b.conf_sequence}
  end

  def new
    @item = Sns::Thread.new({:project_id=>@project.id, :project_sequence=>@project.sequence})
  end

  def create
    @photos = []
    @files = []
    contents = file_params(params)
    @item = Sns::Thread.new(params[:thread])
    @item.contents = contents
    @item.project_id = @project.id
    @item.kind = "thread"
    if @item.save
      @message = "スレッドを作成しました。"
      return redirect_to %Q(#{sns_conferences_path(@project_code)}#conference#{@item.id})
    else
      @message = "スレッドの作成に失敗しました。"
      render :action=>:new
      return
    end
  end

  def edit
    @item = Sns::Thread.find(:first, :conditions=>{:_id=>params[:id]})
    return redirect_to %Q(#{sns_conferences_path(@project_code)}) if @item.blank?
    @photos = []
    @files = []
    @video={:url=>nil, :width=>nil, :height=>nil}
    show_files(@item.contents)
  end

  def update
    @item = Sns::Thread.find(:first, :conditions=>{:_id=>params[:id]})
    contents = file_params(params)
    @item.attributes =params[:item]
    @item.contents = contents
    @item.project_id = @project.id
    @item.last_updated_at = Time.now
    @item.doc_updated_at = Time.now
    @replies = Sns::Thread.where(:kind=>"comment", :parent_id=>@item.id).asc(:created_at)
    if @replies.blank?
      comment_count = 0
    else
      comment_count = @replies.size
    end
    @item.comment_size = comment_count
    if @item.save
      @message = "スレッドを編集しました。"
      return redirect_to %Q(#{sns_conferences_path(@project_code)})
    else
      @message = "スレッドの編集に失敗しました。"
      render :action=>:edit
      return
    end
  end

  def show
    @item = Sns::Thread.find(:first, :conditions=>{:_id=>params[:id]})
    return redirect_to %Q(#{sns_conferences_path(@project_code)}) if @item.blank?
    @photos = []
    @files = []
    @video={:url=>nil, :width=>nil, :height=>nil}
    show_files(@item.contents)
  end


  def destroy
    @item = Sns::Thread.find(:first, :conditions=>{:_id=>params[:id]})
    return redirect_to sns_conferences_path(@project_code) if @item.blank?
    @item.destroy
    return redirect_to sns_conferences_path(@project_code)
  end

  def delete
    @item = Sns::Thread.find(:first, :conditions=>{:_id=>params[:id]})
    return render :text => "NG" if @item.blank?
    return render :text => "NG" unless @item.is_editable? || @project.is_admin?
    @item.destroy
    return render :text => @item.id
  end

  ##comment作成・編集
  def reply
    @photos = []
    @files = []
    contents = file_params(params,{:craeted_user_id=>Core.profile.id})
    @parent = Sns::Thread.find(:first, :conditions=>{:_id=>params[:p_id]})
    @parent.last_updated_at = Time.now
    @parent.save
    @item = Sns::Thread.new(params[:comment])
    @item.created_user_id = Core.profile.id
    @item.parent_id = params[:p_id]
    @item.project_id = @project.id
    @item.project_sequence = @project.sequence
    @item.contents = contents
    @item.kind = "comment"
    @item.title = @parent.title
    @item.last_updated_at = Time.now
    @item.save
    @parent.childs << @item
    @replies = Sns::Thread.where(:kind=>"comment", :parent_id=>@parent.id).asc(:created_at)
    if @replies.blank?
      comment_count = 0
    else
      comment_count = @replies.size
    end
    @parent.comment_size = comment_count
    @parent.save
    respond_to do |format|
      format.js { render :layout=>false }
    end
  end

  def edit_res
    @item = Sns::Thread.find(:first, :conditions=>{:_id=>params[:id]})
    @parent = Sns::Thread.find(:first, :conditions=>{:_id=>@item.parent_id})
    @photos = []
    @files = []
    @video={:url=>nil, :width=>nil, :height=>nil}
    show_files(@item.contents)
  end

  def update_res
    @item = Sns::Thread.find(:first, :conditions=>{:_id=>params[:id]})
    @parent = Sns::Thread.find(:first, :conditions=>{:_id=>@item.parent_id})
    contents = file_params(params)
    @item.attributes =params[:item]
    @item.last_updated_at = Time.now
    @item.contents= contents

    if @item.save
      @message = "コメントを編集しました。"
      @replies = Sns::Thread.where(:kind=>"comment", :parent_id=>@parent.id).asc(:created_at)
      if @replies.blank?
        comment_count = 0
      else
        comment_count = @replies.size
      end
      @parent.comment_size = comment_count
      @parent.last_updated_at = Time.now
      @parent.save
      return redirect_to %Q(#{sns_conferences_path(@project_code)})
    else
      @message = "コメントの編集に失敗しました。"
      render :action=>:edit_res
      return
    end
  end



  def destroy_res
    @parent = Sns::Thread.find(:first, :conditions=>{:_id=>params[:p_id]})
    return redirect_to sns_conferences_path(@project_code) if @parent.blank?
    @item = Sns::Thread.find(:first, :conditions=>{:_id=>params[:id]})
    @item.destroy
    return redirect_to sns_conferences_path(@project_code)
  end

  def delete_res
    @parent = Sns::Thread.find(:first, :conditions=>{:_id=>params[:p_id]})
    return render :text => "NG" if @parent.blank?
    @item = Sns::Thread.find(:first, :conditions=>{:_id=>params[:id]})
    return render :text => "NG" if @item.blank?
    return render render :text => "NG" unless @item.is_editable? || @project.is_admin?
    @item.destroy
    @replies = Sns::Thread.where(:kind=>"comment", :parent_id=>@parent.id).asc(:created_at)
    @parent.comment_size = @replies.size
    if @replies.blank?
      comment_count = 0
    else
      comment_count = @replies.size
    end
    @parent.comment_size = comment_count
    @parent.save
    return render :text => @item.id
  end



  def attach
    @parent_id = params[:parent_id]
    respond_to do |format|
      format.html { render :layout=>false }
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
      elsif f[0]=="video"
        video_item = Sns::Video.find(:first, :conditions=>{:_id=>f[1]})
        @video={:url=>video_item.url, :width=>320, :height=>240, :item=>video_item} if video_item
        @video_url = video_item.url
      end
    end if contents
  end

  def file_params(params,options={})
    contents = []
    pr_group_id = nil
    if params[:photoids]
      @photos = Sns::Photo.any_in("_id"=>params[:photoids])
      @photos.each do |photo|
        photo.update_attributes!(:privacy => "project",
        :pr_group_id => pr_group_id)
        if photo.created_user_name.blank?
          photo.update_attributes!(:created_user_name => Core.user.name,
        :created_group_name => Core.user_group.name,
        :created_group_code => Core.user_group.code,
        :created_group_id => Core.user_group.id )
        end
        contents<<["photo", photo.id]
      end if @photos
    end
    if params[:fileids]
      @files = Sns::File.any_in("_id"=>params[:fileids])
      @files.each do |file|
        file.update_attributes!(:privacy => "project",
        :pr_group_id => pr_group_id)
        if file.created_user_name.blank?
          file.update_attributes!(:created_user_name => Core.user.name,
        :created_group_name => Core.user_group.name,
        :created_group_code => Core.user_group.code,
        :created_group_id => Core.user_group.id )
        end
        contents << ["file", file.id]
      end if @files
    end
    @video={
        :url => params[:video_url],
        :width => params[:width],
        :height => params[:height],
        :item => nil
    }
    if !params[:video_url].blank?
      if options[:craeted_user_id]
        created_user_id = options[:craeted_user_id]
      else
        if @item.blank?
          created_user_id = Core.profile.id
        else
          created_user_id = @item.created_user_id
        end
      end

      f_album = Sns::Album.where(:kind=>"video" , :project_id => @project.id).first
      if f_album
        f_a_id = f_album.id
      else
        new_f_album = Sns::Album.create(:kind=>"video" , :project_id => @project.id, :name => "#{@project.title}の動画")
        f_a_id = new_f_album.id
      end
      query = {:url => params[:video_url],:album_id=>f_a_id,:created_user_id=>created_user_id , :is_project=>1,:project_id=>@project.id}
      video = Sns::Video.where(query).first
      if video.blank?
        video = Sns::Video.new({
            :url => params[:video_url],
            :width => 320,
            :height => 240,
            :privacy=>"project",
            :pr_group_id => nil,
            :album_id=>f_a_id,
            :is_project=>1,
            :project_id=>@project.id,
            :created_user_id=>created_user_id
          })
        video.save
      end
      contents << ["video", video.id]
    end
    return contents
  end

  def feed_post(item)
    parent_project =  @project
    attribute = {
            :text =>%Q(#{parent_project.title}の<a href="#{sns_conferences_path(@project_code)}" >会議室</a>を更新しました。),
            :kind =>["project"],
            :content_id=>[item.id],
            :privacy =>"project",
            :created_user_id=>item.created_user_id,
            :project_id=>parent_project.id,
            :is_project=>1
          }
    Sns::Post.create(attribute)
  end

protected

  def select_layout
    layout = "admin/sns/project"
    layout
  end
end
