# encoding: utf-8
class Sns::Admin::ProfilePhotosController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @edit_current = "photo"
    @cl = params[:cl] || "upload"
  end

  def index
    current_photo = Core.profile.profile_photo_path
    p_sequence = current_photo.gsub(/(\/_admin\/_photos\/)([0-9]+)(.*)/,'\2')
    @album = Sns::Album.find(:first, :conditions=>{:kind=>"photo", :name => "プロフィール写真", :created_user_id=>Core.profile.id})
    @p_photo =  nil
    @p_photo = Sns::Photo.where(:sequence=>p_sequence.to_i, :album_id=>@album.id).first if @album && p_sequence
  end

  def create

    @item = Sns::Photo.new
    photo_upload = @item.photo_data_save(params, :create,{:photo_kind=>:profile})
    if photo_upload
      flash[:notice] = "プロフィール画像を登録しました。"
      return redirect_to sns_profile_photos_path
    else
      flash[:notice] = "プロフィール画像の登録に失敗しました。"
      render :action=>:index
      return
    end
  end

  def destroy
    @item = Sns::Photo.find(params[:id])
    if @item.destroy
      @item.default_photo(Core.profile)
      flash[:notice] = "指定の画像を削除しました。"
    else
      flash[:notice] = "指定の画像の削除に失敗しました。"
    end
    return redirect_to sns_profile_photo_selects_path
  end

  def select
    item = Sns::Photo.find(params[:id])
    if item.blank?
      flash[:notice] = "プロフィール画像の変更に失敗しました。"
    else
      Core.profile.photo_path = item.prof_thumb_public_uri
      Core.profile.thumb_photo_path = item.prof_thumb_public_uri
      if Core.profile.save
        flash[:notice] = "プロフィール画像を変更しました。"
      else
        flash[:notice] = "プロフィール画像の変更に失敗しました。"
      end
    end
    return redirect_to sns_profile_photos_path
  end

protected

  def select_layout
    layout = "admin/sns/config"
    layout
  end

end
