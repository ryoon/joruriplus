# encoding: utf-8
class Sns::Admin::VideosController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
  end

  def index
    if @created_user.id == Core.profile.id
      @items = Sns::Video.where(:created_user_id => @created_user.id).desc(:created_at).paginate(:page => params[:page], :per_page => 20)
    else
      @is_friend = @created_user.is_friend?(Core.profile)
      if @is_friend == true
        @items = Sns::Video.where(:created_user_id => @created_user.id).excludes(:privacy => "closed").desc(:created_at).paginate(:page => params[:page], :per_page => 20)
      else
        @items = Sns::Video.where(:created_user_id => @created_user.id, :privacy => "public").excludes(:privacy => "closed").desc(:created_at).paginate(:page => params[:page], :per_page => 20)
      end
    end

  end

  def show
    @item = Sns::Video.find(:first, :conditions=>{:_id=>params[:id]})
    return redirect_to sns_user_files_path(@created_user.account) if @item.blank?
    return redirect_to sns_user_files_path(@created_user.account) if @item.privacy == "closed" && @created_user.id != Core.profile.id
    return redirect_to sns_user_files_path(@created_user.account) if @item.privacy == "friend" && @is_friend != true
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
      return redirect_to sns_videos_path(@created_user.account)
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
      flash[:notice]="マイ動画を編集しました。"
      return redirect_to sns_videos_path(@created_user.account,@item)
    else
      return redirect_to :action => 'edit'
    end
  end


  def destroy
    @item = Sns::Video.find(:first, :conditions=>{:_id=>params[:id]})
    @item.destroy
    return redirect_to sns_videos_path(@created_user.account)
  end

  def player
    @item = Sns::Video.find(:first, :conditions=>{:_id=>params[:id]})
    respond_to do |format|
      format.js {  }
    end
  end

protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end

end
