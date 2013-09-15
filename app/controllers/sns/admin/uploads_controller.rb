# encoding: utf-8
class Sns::Admin::UploadsController < ApplicationController#Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  protect_from_forgery :except => [:create]
  before_filter :cookie_only_off


  def create
    skip_layout
    @form_kind = params[:form_kind]
    raise "ファイルがアップロードされていません。" if params[:upload].blank?
    original_file_name = params[:upload].original_filename
    #raise "ファイル名に空白を含むファイルはアップロードできません。" if original_file_name.force_encoding(Encoding::UTF_8) =~ /[ 　]+/
    total_size = params[:upload].size
    total_size_limit = params[:total_size_limit] || "5 MB"
    limit_value      = total_size_limit.gsub(/(.*?)[^0-9].*/, '\\1').to_i * (1024**2)
    if total_size > limit_value
      raise "容量制限を超えています。＜#{total_size_limit}＞"
    end
    if @form_kind=="conference" || @form_kind=="note"
      extname = File.extname(original_file_name.force_encoding(Encoding::UTF_8)) # 拡張子を抽出
      filename =  "test#{extname}"
      mime_type = MIME::Types.type_for(filename)
      if mime_type.blank?
        c_type = content_type
      else
        c_type = mime_type[0].to_s
      end
      if c_type =~ /image/
        @form_kind = "photo"
      else
        @form_kind = "file"
      end
    end
    @form_kind = "photo" if @form_kind == "conference_photo"
    @form_kind = "file" if  @form_kind == "conference_file"
    if @form_kind=="file"
      result = file_upload(params)
      image_is = 0
    else
      result = photo_upload(params)
      image_is = 1
    end
      file = result[0]
      rs = result[1]
    raise file.errors.full_messages.join("\n") unless rs
    raise "ファイルが存在しません。(#{file.file_path})" unless FileTest.file?("#{Rails.root.to_s}#{file.file_path}")
    ## garbage collect
    Sys::File.garbage_collect if rand(100) == 0

    #return render :text => "OK #{file.id} #{file.file_name}"
    return render :text => "OK:#{file.id}:#{file.original_file_name}:#{file.eng_unit}:#{image_is}:#{file.file_name}"
  rescue => e
    render :text => "Error #{e}"
  end

  def file_upload(params)
    options = {}
    if params[:project_id]
      options[:is_project]=1
      options[:is_project]= params[:is_project].to_i if params[:is_project]
      options[:project_id]=params[:project_id]
    end
    options[:group_id] = params[:group_id]
    options[:core_profile_id] = params[:core_profile_id]
    par_item = {
      :upload => params[:upload],
      :privacy => "closed"
    }
    if params[:album_kind]
      options[:file_kind] = :feed  if params[:album_kind] == "feed"
      options[:file_kind] = :note  if params[:album_kind] == "note"
    end
    params[:item] = par_item
    file = Sns::File.new
    begin
      rs = file.file_data_save(params, :create,options)
    rescue => e
      raise "ファイルの保存に失敗しました。#{e}"
    end
    return [file, rs]
  end

  def photo_upload(params)
    options = {}
    if params[:project_id]
      options[:is_project]=1
      options[:is_project]= params[:is_project] if params[:is_project]
      options[:project_id]=params[:project_id]
    end
    options[:group_id] = params[:group_id]
    if params[:album_id]
      @album = Sns::Album.find(params[:album_id])
      if @album.name == "プロフィール写真"
        options[:photo_kind]=:profile
      end unless @album.blank?
    end
    if params[:album_kind]
      options[:photo_kind] = :feed  if params[:album_kind] == "feed"
      options[:file_kind] = :note  if params[:album_kind] == "note"
    end
    options[:core_profile_id] = params[:core_profile_id]
    par_item = {
      :upload => params[:upload],
      :privacy => "closed"
    }
    params[:item] = par_item
    file = Sns::Photo.new
    begin
      rs = file.photo_data_save(params, :create,options)
    rescue => e
      raise "ファイルの保存に失敗しました。#{e}"
    end
    return [file, rs]
  end

  def destroy
    raise "送信パラメータが不正です。" if params[:id].blank?
    raise "送信パラメータが不正です。" if params[:kind].blank?
    @form_kind = params[:kind]
    if @form_kind ==  "conference"
      if params[:image_is]=="1"
        @form_kind = "photo"
      else
        @form_kind = "file"
      end
    end
    if @form_kind=="photo"
      @item = Sns::Photo.find(:first, :conditions=>{:_id=>params[:id]})
    elsif @form_kind=="file"
      @item = Sns::File.find(:first, :conditions=>{:_id=>params[:id]})
    end
      @item.destroy
      render :text => "OK #{params[:id]}"
    rescue => e
      return http_error(404)
  end
protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end

  def cookie_only_off
    request.session_options[:cookie_only] = false
    request.session_options[:only]        = :create
  end

end
