# encoding: utf-8
class Sns::Admin::AlbumsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @created_user = Core.profile
  end

  def new
    @item = Sns::Album.new
    @item.created_user_id  = Core.profile
  end

  def create
    @item = Sns::Album.new(params[:item])
    @item.state = "enabled"
    if @item.save
      items = Sns::Photo.any_in("_id"=>params[:ids])
      items.each do |file|
        file.update_attributes!(:privacy => @item.privacy ,:album_id=>@item.id)
      end
      flash[:notice]="アルバムを作成しました。"
      return redirect_to sns_profile_photos_path({:album_id=>@item.id})
    else
      flash[:notice]
      render :action=>:new
      return
    end
  end

  def edit
    @item = Sns::Album.find(params[:id])
  end

  def update
    @item = Sns::Album.find(params[:id])
    @item.attributes = params[:item]
    if @item.save
      flash[:notice] =  "アルバムを編集しました。"
      return redirect_to sns_profile_photos_path({:album_id=>@item.id})
    else
      render :action=>:edit
    end
  end

  def destroy
    @item = Sns::Album.find(:first, :conditions=>{:_id=>params[:id]})
    @item.destroy
    return redirect_to sns_profile_photos_path({:album_id=>@item.id})
  end


protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end

end
