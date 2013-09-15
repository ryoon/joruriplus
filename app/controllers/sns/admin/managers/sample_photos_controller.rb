# -*- encoding: utf-8 -*-
class Sns::Admin::Managers::SamplePhotosController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @album = Sns::Album.where(:kind=>"manager", :name=>"サンプル用フォト").first
    if @album.blank?
      @album = Sns::Album.create({:kind=>"manager", :name=>"サンプル用フォト",:created_user_id=>nil,:is_project=>0,:privacy=>"public"})
    end
    return redirect_to "/_admin" unless Core.user.has_auth?(:manager)
    @current = "sample"
  end


  def index
    @items = Sns::Photo.where(:album_id=>@album.id).excludes(:is_project=>1).paginate(:page => params[:page], :per_page => 20)
  end

  def show
    @item = Sns::Photo.find(:first, :conditions=>{:_id => params[:id]})
    return redirect_to sns_user_photos_path(@created_user.account) if @item.blank?
    @album = Sns::Album.find(@item.album_id)
  end

  def new
    @item = Sns::Photo.new
  end

  def create
    @item = Sns::Photo.new
    options={}
    if @item.photo_data_save(params, :create,{:photo_kind=>:sample})
      flash[:notice] = "フォトを登録しました。"
      return redirect_to sns_sample_photo_path(@item)
    else
      render :action=>:new
    end
  end


  def edit
    @item = Sns::Photo.find(:first, :conditions=>{:_id=>params[:id]})
  end

  def update
    @item = Sns::Photo.find(:first, :conditions=>{:_id=>params[:id]})
    options={}
    if @item.photo_data_save(params, :update,{:photo_kind=>:sample})
      flash[:notice] = "フォトを編集しました。"
      return redirect_to sns_sample_photo_path(@item)
    else
      render :action=>:edit
    end
  end

  def destroy
    @item = Sns::Photo.find(:first, :conditions=>{:_id=>params[:id]})
    @item.destroy
    return redirect_to sns_sample_photos_path
  end


  def crop
    @item = Sns::Photo.where(:_id=>params[:id]).first
    if @item.blank?
      return render :text => "NG"
    end
    x = params[:px].to_i
    y = params[:py].to_i
    width = params[:width].to_i
    height = params[:height].to_i
    do_crop = @item.profile_thumbnail(x, y, width, height)
    if do_crop
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
