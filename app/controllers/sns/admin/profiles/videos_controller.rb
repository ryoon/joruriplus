# encoding: utf-8
class Sns::Admin::Profiles::VideosController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @created_user = Sns::Profile.find(:first, :conditions=>{:account=>params[:account]})
    return redirect_to "/_admin" if @created_user.blank?
    @is_friend = @created_user.is_friend?(Core.profile)
    @u_role = false
    @u_role = true if @created_user.account==Core.profile.account
  end

  def index
    @items = Sns::Video.post_user(@created_user.id).is_friend_post(@is_friend).desc(:created_at).paginate(:page => params[:page], :per_page => 20)
  end

  def show
    @item = Sns::Video.find(:first, :conditions=>{:_id=>params[:id]})
    return redirect_to sns_user_videos_path(@created_user.account) if @item.blank?
    return redirect_to sns_user_videos_path(@created_user.account) if @item.privacy == "closed" && @created_user.id != Core.profile.id
    return redirect_to sns_user_videos_path(@created_user.account) if @item.privacy == "friend" && @is_friend != true
  end


  def new
    @item = Sns::Video.new
    @item.created_user_id = Core.profile.id
    @item.width = 320
    @item.height = 240
  end

  def create
    @item = Sns::Video.new(params[:item])
    if @item.save
      flash[:notice]="マイ動画を追加しました。"
      return redirect_to sns_user_videos_path(@created_user.account)
    else
      return redirect_to :action => 'new'
    end
  end


  def edit
    @item = Sns::Video.find(:first, :conditions=>{:_id=>params[:id]})
  end

  def update
    @item = Sns::Video.find(:first, :conditions=>{:_id=>params[:id]})
    if @item.save
      range_change
      flash[:notice]="マイ動画を編集しました。"
      return redirect_to sns_user_videos_path(@created_user.account,@item)
    else
      return redirect_to :action => 'edit'
    end
  end


  def destroy
    @item = Sns::Video.find(:first, :conditions=>{:_id=>params[:id]})
    @item.destroy
    return redirect_to sns_user_videos_path(@created_user.account)
  end

  def range_change
    post_item = Sns::Post.where(:kind=>"video").where(:video_ids=>@item.id).where(:created_user_id=>Core.profile.id).first
    unless post_item.blank?
      post_item.privacy = @item.privacy
      post_item.pr_group_id = @item.pr_group_id
      post_item.save(:validate=>false)
    end
  end


protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end

end
