# encoding: utf-8
class Sns::Admin::Profiles::PhotosController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    if params[:account]
      @created_user = Sns::Profile.find(:first, :conditions=>{:account=>params[:account]})
      @is_friend = @created_user.is_friend?(Core.profile)
      return redirect_to "/_admin" if @created_user.blank?
      @u_role = false
      @u_role = true if @created_user.account==Core.profile.account
    end
  end

  def index
    if params[:album_id].blank? || params[:album_id].to_i == 0
      @albums = Sns::Album.post_user(@created_user.id).is_friend_post(@is_friend).excludes(:is_project=>1).paginate(:page => params[:page], :per_page => 20)
      @items = nil
    else
      @albums = Sns::Album.find(:first, :conditions=>{:_id=>params[:album_id]})
      @items = Sns::Photo.where(:album_id=>params[:album_id]).is_friend_post(@is_friend).excludes(:is_project=>1).paginate(:page => params[:page], :per_page => 20)
    end
  end

  def show
    @item = Sns::Photo.find(:first, :conditions=>{:_id => params[:id]})
    return redirect_to sns_user_photos_path(@created_user.account) if @item.blank?
    @album = Sns::Album.find(@item.album_id)
  end

  def new
    @item = Sns::Photo.new
    @album = Sns::Album.find(params[:album_id])
    return redirect_to sns_user_photos_path(@created_user.account) if @album.blank?
    @item.album_id = params[:album_id]
    @item.created_user_id = @created_user.id
  end

  def create
    @album = Sns::Album.find(params[:item][:album_id])
    if @album.name == "プロフィール写真"
      options[:photo_kind]=:profile
    end
    return sns_user_photos_path(@created_user.account) if @album.blank?
    flash[:notice]="ファイルを追加しました。"
    return redirect_to sns_user_photos_path(@created_user.account,{:album_id=>@album.id})
  end


  def edit
    @item = Sns::Photo.find(:first, :conditions=>{:_id=>params[:id]})
  end

  def update
    @item = Sns::Photo.find(:first, :conditions=>{:_id=>params[:id]})
    @album = Sns::Album.find(params[:item][:album_id])
    options={}
    if @album.name == "プロフィール写真"
      options[:photo_kind]=:profile
    end
    if @item.photo_data_save(params, :update,options)
      range_change(params)
      flash[:notice] = "フォトを編集しました。"
      return redirect_to sns_user_photo_path(@created_user.account, @item)
    else
      render :action=>:edit
    end
  end

  def range_change(params)
    if params[:item][:privacy]=="group"
      pr_group_id = Core.user_group.id
    else
      pr_group_id = nil
    end
    post_item = Sns::Post.where(:photo_ids=>params[:id]).where(:created_user_id=>Core.profile.id).first
    unless post_item.blank?
      post_item.privacy = params[:item][:privacy]
      post_item.pr_group_id = pr_group_id
      post_item.save(:validate=>false)
      other_ids = post_item.photo_ids
      other_ids.delete(params[:id])
      other_ids.each do |o|
        other_item = Sns::Photo.find(o)
        if other_item
          other_item.privacy = params[:item][:privacy]
          other_item.pr_group_id = pr_group_id
          other_item.save(:validate=>false)
        end
      end
    end
  end

  def destroy
    @item = Sns::Photo.find(:first, :conditions=>{:_id=>params[:id]})
    @item.destroy
    @item.default_photo(@created_user)
    if params[:account]
      return_uri = "/_admin/profile/#{params[:account]}?cl=photo&album_id=#{@item.album_id}"
    else
      return_uri = sns_user_photos_path(@created_user.account,{:album_id=>@item.album_id})
    end
    return redirect_to return_uri
  end

protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end
end
