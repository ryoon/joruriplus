# encoding: utf-8
class Sns::Admin::ProfilePhotoSelectsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @edit_current = "photo"
    @album = Sns::Album.find(:first, :conditions=>{:kind=>"photo", :name => "プロフィール写真", :created_user_id=>Core.profile.id})
  end

  def index
    skip_layout
    if @album.blank?
      @photos = nil
    else
      @photos = Sns::Photo.find(:all, :conditions=>{:album_id => @album.id})
    end
    sample_album = Sns::Album.where(:kind=>"manager", :name=>"サンプル用フォト").first
    if sample_album.blank?
      @samples = nil
    else
      @samples = Sns::Photo.find(:all, :conditions=>{:album_id => sample_album.id})
    end
  end


  def upload
    skip_layout
    @item = Sns::Photo.new
    par_item = {
      :upload => params[:upload],
      :privacy => "public",
      :caption=> params[:caption]
    }
    params.delete :upload
    params.delete :caption
    params[:item] = par_item
    photo_upload = @item.save_from_webcam(params, :create,{:photo_kind=>:profile, :encoded=>true})
    if photo_upload
      Core.profile.photo_path = @item.resized_public_uri
      Core.profile.thumb_photo_path = @item.thumb_public_uri
      Core.profile.save
      result = "OK #{@item.public_uri}"
    else
      result = "NG no_image"
    end
    return render :text => result
  end

  def crop
    return render :text => "NG" if @album.blank?
    prof_uri = Core.profile.profile_photo_path
    return render :text => "NG" if prof_uri == "/_common/themes/admin/sns/images/sample.jpg"
    sequence = prof_uri.gsub(/\/_admin\/_photos\/([0-9]*).*/,'\1')
    @item = Sns::Photo.where(:sequence=>sequence.to_i, :album_id=>@album.id).first
    if @item.blank?
      return render :text => "NG"
    end
    x = params[:px].to_i
    y = params[:py].to_i
    width = params[:width].to_i
    height = params[:height].to_i
    do_crop = @item.profile_thumbnail(x, y, width, height)
    if do_crop
      Core.profile.photo_path = @item.prof_thumb_public_uri
      Core.profile.thumb_photo_path = @item.prof_thumb_public_uri
      Core.profile.save
      time_params = Time.now.to_i
      result = "OK #{@item.prof_thumb_public_uri}&#{time_params}"
    else
      result = "NG no_image"
    end
    return render :text => result
  end

  def webcam_crop
    prof_uri = Core.profile.profile_photo_path
    return render :text => "NG" if prof_uri == "/_common/themes/admin/sns/images/sample.jpg"
    sequence = prof_uri.gsub(/\/_admin\/_photos\/([0-9]*).*/,'\1')
    @item = Sns::Photo.where(:sequence=>sequence.to_i, :album_id=>@album.id).first
    if @item.blank?
      return render :text => "NG"
    end
    x = params[:px].to_i
    y = params[:py].to_i
    width = params[:width].to_i
    height = params[:height].to_i
    do_crop = @item.profile_thumbnail(x, y, width, height)
    if do_crop
      Core.profile.photo_path = @item.prof_thumb_public_uri
      Core.profile.thumb_photo_path = @item.prof_thumb_public_uri
      Core.profile.save
      time_params = Time.now.to_i
      result = "OK #{@item.prof_thumb_public_uri}&#{time_params}"
    else
      result = "NG no_image"
    end
    return render :text => result
  end

protected

  def select_layout
    layout = "admin/sns/config"
    layout
  end

end
