# encoding: utf-8
class Sns::Admin::PhotosController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
  end

  def index
    if params[:album_id].blank? || params[:album_id].to_i == 0
      @albums = Sns::Album.where(:created_user_id => Core.profile.id).excludes(:is_project=>1).paginate(:page => params[:page], :per_page => 20)
      @items = nil
    else
      @albums = Sns::Album.find(:first, :conditions=>{:_id=>params[:album_id]})
      @items = Sns::Photo.where(:album_id=>params[:album_id]).excludes(:is_project=>1).paginate(:page => params[:page], :per_page => 20)
    end
  end

  def show
    skip_layout
    sequence = params[:id].to_i
    @item = Sns::Photo.find(:first, :conditions=>{:sequence =>sequence})
    return http_error(404) if @item.blank?
  end

  def new
    @item = Sns::Photo.new
    @album = Sns::Album.find(params[:album_id])
    return redirect_to sns_photos_path(@created_user.account) if @album.blank?
    @item.album_id = params[:album_id]
    @item.created_user_id = @created_user.id
  end

  def create
    @album = Sns::Album.find(params[:item][:album_id])
    return sns_photos_path(@created_user.account) if @album.blank?
    items = Sns::Photo.any_in("_id"=>params[:ids])
    items.each do |file|
      file.update_attributes!(:privacy => params[:item][:privacy] ,:album_id=>@album.id, :caption=>[:item][:caption])
    end
    flash[:notice]="ファイルを追加しました。"

    return redirect_to sns_photos_path(@created_user.account,{:album_id=>@album.id})
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
      flash[:notice] = "プロフィールを編集しました。"
      return redirect_to sns_photo_path(@created_user.account, @item)
    else
      render :action=>:edit
    end
  end


  def destroy
    @item = Sns::Photo.find(:first, :conditions=>{:_id=>params[:id]})
    @item.destroy
    @item.default_photo(@created_user)
    if params[:account]
      return_uri = "/_admin/profile/#{params[:account]}?cl=photo&album_id=#{@item.album_id}"
    else
      return_uri = sns_photos_path(@created_user.account,{:album_id=>@item.album_id})
    end
    return redirect_to return_uri
  end


  def down
    params_path = params[:path].split('/')
    sequence = params_path[0].gsub(/\..*$/, '').to_i
    item = Sns::Photo.find(:first, :conditions=>{:sequence =>sequence,:file_name=>params_path[0]})
    return http_error(404) if item.blank?
    return http_error(404) unless item.auth_check if !item.privacy.blank?
    if params[:size]
      if params[:size] == "thumb"
        file_path = item.thumb_file_path
      elsif params[:size] =="p_thumb"
        file_path = item.prof_thumb_path
      else
        file_path = item.resize_file_path
      end
    else
      file_path = item.file_path
    end
    if file_path =~ /upload/
      filename = "#{Rails.root.to_s}#{file_path}"
    else
      filename = "#{Rails.root.to_s}/upload#{file_path}"
    end
    #IE判定
    chk = request.headers['HTTP_USER_AGENT']
    chk = chk.index("MSIE")
    if chk.blank?
      item_filename = item.original_file_name
    else
      item_filename = item.original_file_name.tosjis
    end
    disposition = 'inline'
    disposition = 'attachment' if params[:mode]=="download"
    return send_file(filename, :filename => item_filename, :disposition => disposition, :type=>item.content_type, :x_sendfile => true)
  end


protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end
end
