# -*- encoding: utf-8 -*-
require 'mime/types'
class Sns::Photo
  include Mongoid::Document
  include Mongoid::Timestamps
  include Sns::Model::File
  include Sns::Model::Base
  include Sns::Model::Privacy
  include Sns::Model::Creator

  after_destroy :destroy_file

  field :file_name
  field :file_path
  field :file_directory
  field :resize_file_path
  field :thumb_file_path
  field :prof_thumb_path
  field :original_file_name
  field :content_type
  field :created_user_id
  field :album_id
  field :privacy
  field :size
  field :file_size
  field :caption
  field :sequence, :type=>Float
  field :is_project, :type=>Integer
  field :project_id
  field :conference_id
  field :pr_group_id
  field :width
  field :height
  field :resized_width
  field :resized_height
  field :publised_user_id, :type=>Array
  field :created_user_name
  field :created_group_name
  field :created_group_code
  field :created_group_id, :type=>Integer

  before_create :set_creator_infomation

  after_create :set_group_id

  referenced_in :album, :class_name=>"Sns::Album"
  referenced_in :created_user, :class_name=>"Sns::Profile"

  referenced_in :project, :class_name=>"Sns::Project"


  def set_group_id
    return if self.privacy != "group"
    self.pr_group_id = Core.user_group.id
    self.save(:validate=>false)
  end

  def prof_thumb_public_uri
    return nil unless Core
    return thumb_public_uri if self.prof_thumb_path.blank?
    "/_admin/_photos/#{escaped_name}?size=p_thumb"
  end

  def thumb_public_uri
    return nil unless Core
    "/_admin/_photos/#{escaped_name}?size=thumb"
  end

  def resized_public_uri
    return nil unless Core
    "/_admin/_photos/#{escaped_name}?size=resized"
  end

  def show_uri
    return nil unless Core
    "/_admin/sns/_photos/#{escaped_name}"
  end

  def public_uri
    return nil unless Core
    "/_admin/_photos/#{escaped_name}"
  end

  def download_uri
    "/_admin/_photos/#{escaped_name}?mode=download"
  end

  def project_photo_path
    return if self.project.blank?
    "/_admin/sns/projects/#{self.project.code}/photos/#{self.id}"
  end


  def photo_data_save(params, mode,options={})
    if Core.profile.blank?
      core_profile_id = options[:core_profile_id]
    else
      core_profile_id =Core.profile.id
    end
    if Core.user_group.blank?
      group_id = options[:group_id]
    else
      group_id = Core.user_group.id
    end
    extname_judges = [".jpeg", ".jpg", ".png", ".gif"]
    par_item = params[:item].dup
    file = par_item[:upload]
    par_item.delete :upload
    par_item.delete :local_file_path
    update_image = Hash::new # 更新時、ファイルがアップロードされていない場合は、既存のファイル情報を継続させる。
    unless file.blank?
      upload_file = file.read
      content_type = file.content_type
      file_size = file.size
      original_file_name = file.original_filename # ファイル名
      extname = File.extname(original_file_name) # 拡張子を抽出
      if extname_judges.index(extname.downcase).blank? # downcase：小文字に揃える、index：配列を検索
        self.errors.add :upload, '　jpeg, jpg, png, gifの拡張子以外の画像をアップロードできません。'
      end
    else
      if mode == :create
        self.errors.add :upload, 'を選択してください。'
      elsif mode == :update
        update_image[:file_path] = self.file_path
        update_image[:file_directory] = self.file_directory
        update_image[:file_name] = self.file_name
        update_image[:thumb_file_path] = %Q(#{self.file_directory}small_#{self.file_name})
        update_image[:original_file_name] = self.original_file_name
        update_image[:content_type] = self.content_type
        update_image[:privacy] = par_item[:privacy]
        update_image[:size] = self.size
        update_image[:file_size] = self.file_size
        update_image[:pr_group_id] = group_id if par_item[:privacy] == "group"
        update_image[:width] = self.width
        update_image[:height] = self.height
        update_image[:resized_width] = self.resized_width
        update_image[:resized_height] = self.resized_height
      end
    end
    if options[:is_project]
      project = Sns::Project.find(:first, :conditions=>{:_id=>options[:project_id]})
      file_size_limit = project.file_size_limit
      self.errors.add :upload, '　プロジェクトのファイルサイズ上限をオーバーしています。' if file_size_limit== false
    end

    save_flg = self.errors.size
    # 画像アップ
    if save_flg && !file.blank?
      #連番を設定
      sequence_number if self.sequence.blank?
      image = Hash::new
      if options[:photo_kind] == :profile
        album_id = album_exist("プロフィール写真",core_profile_id)
      elsif options[:photo_kind] == :feed
        album_id = album_exist("ニュースフィード",core_profile_id)
      elsif options[:photo_kind] == :note
        album_id = album_exist("ノート",core_profile_id)
      else
        album_id = par_item[:album_id]
      end
      if options[:is_project]
        project = Sns::Project.find(:first, :conditions=>{:_id=>options[:project_id]})
        if project
          album_id = album_exist("「#{project.title}」の写真",core_profile_id,{:is_project=>options[:is_project],:project_id=>options[:project_id]})
        else
          album_id = nil
        end
        image[:project_id]=options[:project_id]
        image[:is_project]=1
      end
      image[:album_id] = album_id
      sequense_str = "#{format('%08d', self.sequence)}"
      filename =  "#{sequense_str}#{extname}"
      mime_type = MIME::Types.type_for(filename)
      if mime_type.blank?
        image[:content_type] = content_type
      else
        image[:content_type] = mime_type[0].to_s
      end
      image[:original_file_name] = original_file_name
      image[:size]=file.size
      dir = sequense_str.gsub(/(.*)(..)(..)(..)$/, '\1/\2/\3/\4/\1\2\3\4')
      upload_name = "#{sequense_str}.dat"
      directory = "/upload/sns/photo/#{dir}/"
      image[:file_directory] = directory
      image[:file_name] = filename
      image[:created_user_id] = core_profile_id
      image[:privacy] = par_item[:privacy]
      file_path = %Q(#{directory}#{upload_name})
      image[:file_path] = file_path
      resize_file_path = %Q(#{directory}resize_#{upload_name})
      image[:resize_file_path] = resize_file_path
      thumb_file_path = %Q(#{directory}small_#{upload_name})
      image[:thumb_file_path] = thumb_file_path
      image[:file_size] = file_size
      upload_path = Rails.root.to_s
      upload_path += '/' unless upload_path.ends_with?('/')
      upload_path += "#{file_path}"
      upload_resize_file_path = Rails.root.to_s
      upload_resize_file_path += '/' unless upload_resize_file_path.ends_with?('/')
      upload_resize_file_path += "#{resize_file_path}"
      upload_thumb_file_path = Rails.root.to_s
      upload_thumb_file_path += '/' unless upload_thumb_file_path.ends_with?('/')
      upload_thumb_file_path += "#{thumb_file_path}"
      unless mkdir_for_file(upload_path)
        # ディレクトリが作成できない
        self.errors.add :upload, 'ディレクトリが作成できません。'
      end
      if self.errors.size == 0
        #実ファイルを保存
        File.delete(upload_path) if File.exist?(upload_path)
        File.open(upload_path, 'wb') { |f| f.write(upload_file) }
        #リサイズ画像を保存
        File.delete(upload_resize_file_path) if File.exist?(upload_resize_file_path)
        File.open(upload_resize_file_path, 'wb') { |f| f.write(upload_file) }
        #サムネイルを保存
        File.delete(upload_thumb_file_path) if File.exist?(upload_thumb_file_path)
        File.open(upload_thumb_file_path, 'wb') { |f| f.write(upload_file) }
        #画像サイズを取得
        image_size = photo_size(upload_file)
        if image_size[0]==true
          reduce_size = reduce(upload_path,image_size,options)
          image[:width] = reduce_size[0]
          image[:height] = reduce_size[1]
          image[:file_size]= reduce_size[2] unless reduce_size[2].blank?
          resized_size = resize(upload_resize_file_path,image_size,options)
          image[:resized_width] = resized_size[0]
          image[:resized_height] = resized_size[1]
          p_file_path = upload_resize_file_path.gsub(/resize/,"p_thumb")
          if image[:resized_width] > image[:resized_height] || image[:resized_height] > image[:resized_width]
            p_thum_image = image[:resized_height] if image[:resized_width] > image[:resized_height]
            p_thum_image = image[:resized_width] if image[:resized_width] < image[:resized_height]
            profile_thumbnail(0, 0, p_thum_image, p_thum_image,{:p_file_path=>p_file_path,:original_path=>upload_resize_file_path})
            image[:prof_thumb_path]=p_file_path.gsub(Rails.root.to_s,"")
          end
          thumbnail(upload_thumb_file_path,image_size,options)
        end
        self.update_attributes(image)
        self.save
        return true
      else
        return false
      end
    elsif save_flg && file.blank? && mode == :update
      # 既存データを保存
      self.update_attributes(update_image)
      self.save
      return true
    else
      return false
    end
  end

  def save_from_webcam(params, mode,options={})
    if Core.profile.blank?
      core_profile_id = options[:core_profile_id]
    else
      core_profile_id =Core.profile.id
    end
    par_item = params[:item].dup
    upload_file = par_item[:upload].gsub('data:image/png;base64,', '').unpack("m")[0]
    #連番を設定
    sequence_number if self.sequence.blank?
    image = Hash::new
    album_id = album_exist("プロフィール写真",core_profile_id)
    image[:album_id] = album_id
    sequense_str = "#{format('%08d', self.sequence)}"
    filename =  "#{sequense_str}.png"
    image[:content_type] = "image/png"
    image[:original_file_name] = "webcam.png"
    dir = sequense_str.gsub(/(.*)(..)(..)(..)$/, '\1/\2/\3/\4/\1\2\3\4')
    upload_name = "#{sequense_str}.dat"
    directory = "/sns/photo/#{dir}/"
    image[:file_directory] = directory
    image[:file_name] = filename
    image[:created_user_id] = core_profile_id
    image[:privacy] = par_item[:privacy]
    file_path = %Q(#{directory}#{upload_name})
    image[:file_path] = file_path
    resize_file_path = %Q(#{directory}resize_#{upload_name})
    image[:resize_file_path] = resize_file_path
    thumb_file_path = %Q(#{directory}small_#{upload_name})
    image[:thumb_file_path] = thumb_file_path
    upload_path = Rails.root.to_s
    upload_path += '/' unless upload_path.ends_with?('/')
    upload_path += "/upload#{file_path}"
    upload_resize_file_path = Rails.root.to_s
    upload_resize_file_path += '/' unless upload_resize_file_path.ends_with?('/')
    upload_resize_file_path += "upload#{resize_file_path}"
    upload_thumb_file_path = Rails.root.to_s
    upload_thumb_file_path += '/' unless upload_thumb_file_path.ends_with?('/')
    upload_thumb_file_path += "upload#{thumb_file_path}"
    image[:width] = 240
    image[:height] = 240
    unless mkdir_for_file(upload_path)
      # ディレクトリが作成できない
      self.errors.add :upload, 'ディレクトリが作成できません。'
    end
    if self.errors.size == 0
      #実ファイルを保存
      File.delete(upload_path) if File.exist?(upload_path)
      File.open(upload_path, 'wb') { |f| f.write(upload_file) }
      #リサイズ画像を保存
      File.delete(upload_resize_file_path) if File.exist?(upload_resize_file_path)
      File.open(upload_resize_file_path, 'wb') { |f| f.write(upload_file) }
      #サムネイルを保存
      File.delete(upload_thumb_file_path) if File.exist?(upload_thumb_file_path)
      File.open(upload_thumb_file_path, 'wb') { |f| f.write(upload_file) }
      #画像サイズを取得
      self.update_attributes(image)
      self.save
      return true
    else
      return false
    end
  end

  def album_exist(name,core_profile_id,options={})
    if options[:is_project]
      album = Sns::Album.find(:first, :conditions=>{:project_id => options[:project_id], :kind=>"photo"})
    else
      album = Sns::Album.find(:first, :conditions=>{:created_user_id => core_profile_id, :name=>name, :kind=>"photo"})
    end
    if album.blank?
      params = {:kind=>"photo",:created_user_id => core_profile_id, :name=>name, :state=>"public",:is_project=>options[:is_project],:project_id=>options[:project_id]}
      new_album = Sns::Album.create(params)
      profile_album_id = new_album.id
    else
      profile_album_id = album.id
    end
    return profile_album_id
  end

  def reduce(upload_path,image_size,options)
    do_resize = false
    if image_size[1] > 1024
      do_resize = true
      width = 1024
      height = 1024
    elsif image_size[2] > 768
      do_resize = true
      width = 768
      height = 768
    else
      if options[:photo_kind]==:profile || options[:photo_kind]==:sample
        do_resize = true
        if image_size[1] > image_size[2]
          width = image_size[1]
          height = image_size[1]
        else
          width = image_size[2]
          height = image_size[2]
        end
      end
    end
    if do_resize == true
      ret = image_resize(upload_path,width, height,options)
    else
      ret = [image_size[1], image_size[2],nil]
    end
     return ret
  end

  def resize(upload_path,image_size,options)
    do_resize = false

    if image_size[1] > 500 || image_size[2] > 500
      do_resize = true
      width = 500
      height = 500
    end
    if do_resize == true
      ret = image_resize(upload_path,width, height,options)
      p_tumb_size = 400
    else
      if image_size[1] > image_size[2]
        p_tumb_size = image_size[2]
      else
        p_tumb_size = image_size[1]
      end
      ret = [image_size[1], image_size[2],nil]
    end

    return ret
  end

  def thumbnail(upload_path,image_size,options={})
    do_resize = false
    if image_size[1] > 200 || image_size[2] > 200
      do_resize = true
      width = 200
      height = 200
    end
    if do_resize == true
      ret = image_resize(upload_path,width, height,options)
    else
      ret = [image_size[1], image_size[2],nil]
    end
    return ret
  end

  def image_resize(upload_path,width,height,options={})
    begin
      require 'RMagick'
      original = Magick::Image.read(upload_path).first
      resized = original.resize_to_fit(width,height)
      resized.write(upload_path)
      width = resized.columns
      height = resized.rows
      size = resized.filesize
      return [width, height,size]
    rescue
      return [0, 0,nil]
    end
  end

  def profile_thumbnail(x, y, width, height,options={})
    sequense_str = "#{format('%08d', self.sequence)}"
    upload_name = "#{sequense_str}.dat"
    if options[:p_file_path]
      upload_path = options[:p_file_path]
    else
      if self.file_directory =~ /upload/
        p_file_path = "#{self.file_directory}p_thumb_#{upload_name}"
      else
        p_file_path = "/upload#{self.file_directory}p_thumb_#{upload_name}"
      end

      upload_path = %Q(#{Rails.root.to_s}#{p_file_path})
    end
    if options[:original_path]
      original_path = options[:original_path]
    else
      if self.resize_file_path =~ /upload/
        original_path = "#{Rails.root.to_s}#{self.resize_file_path}"
      else
        original_path = "#{Rails.root.to_s}/upload#{self.resize_file_path}"
      end
    end
    crop = image_crop(original_path, upload_path,width, height, x, y)
    if crop
      if options[:original_path].blank?
        self.prof_thumb_path = p_file_path
        self.save
      end
      return true
    else
      return false
    end
  end

  def image_crop(original_path,upload_path, x, y, width, height)
    begin
      require 'RMagick'
      File.delete(upload_path) if File.exist?(upload_path)
      original = Magick::Image.read(original_path).first
      image = original.crop(width, height,x, y,true)
      if File.exist?(upload_path)
        image.write(upload_path)
      else
        FileUtils::cp(original_path,upload_path)
        image.write(upload_path)
      end
      return true
    rescue
      return false
    end
  end

  #縦横サイズ取得
  def photo_size(file)
    begin
      require 'RMagick'
      image = Magick::Image.from_blob(file).shift
      if image.format =~ /(GIF|JPEG|PNG)/
        result = true
        width = image.columns
        height = image.rows
        reason = "ok"
      else
        result = false
        width = 0
        height = 0
        reason = "format"
      end
    rescue
      result = false
      width = 0
      height = 0
      reason = "rmagickerr"
    end
    return [result,width,height,reason]
  end

  def destroy_feed
    photo_feed = Sns::Post.where({:kind=>"photo",:content_id=>self.id,:created_user_id=>Core.profile.id})
    photo_feed.destroy_all unless photo_feed.blank?
  end

  def destroy_file
    if file_path =~ /upload/
      src = "#{Rails.root.to_s}#{self.file_directory}"
    else
      src = "#{Rails.root.to_s}/upload#{self.file_directory}"
    end
    FileUtils.rm_rf(src)
    rescue => e
  end

  def default_photo(profile)
    if self.resized_public_uri == Core.profile.photo_path || self.prof_thumb_public_uri == Core.profile.photo_path
      profile.photo_path = nil
      profile.thumb_photo_path = nil
      profile.save
    end
  end

  #ファイル出力オプション
  def display_options(options={})
    resize_width = 200
    resize_height = 500
    resize_width = options[:width] if options[:width]
    resize_height = options[:height] if options[:height]
    ret = {:width => resize_width}
    unless self.resized_width.blank?
      if self.resized_width < resize_width
        ret = {:width=>self.resized_width}
      end
      unless self.resized_height.blank?
        if self.resized_height >= resize_height && self.resized_width < resize_width
          ret = {:height => resize_height}
        end
      end
    end
    ret[:alt] = self.original_file_name
    return ret
  end
  class << self
    #検索用criteria

    def post_user(id)
      criteria.where(:created_user_id => id)
    end
    def p_call(friend_ids)
      friend_hash = [{ :privacy => "friend", :created_user_id=>friend_ids }, { :privacy => "friend", :created_user_id=>Core.profile.id}]
      if friend_ids
        query_h = [
        { :privacy => "public" },
        { :privacy => "closed",:created_user_id=>Core.profile.id },
        {:privacy=>"group", :pr_group_id=>Core.user_group.id},
        friend_hash
        ]
      else
        query_h = [
        { :privacy => "public" },
        { :privacy => "closed",:created_user_id=>Core.profile.id },
        {:privacy=>"group", :pr_group_id=>Core.user_group.id},]
      end
      cg_ids = Sns::CustomGroup.any_of({:friend_user_id => Core.profile.id},{:user_id=>Core.profile.id}).map(&:sequence)
      cg_ids.each do |cg|
        query_h << {:privacy=>cg}
      end unless cg_ids.blank?
      criteria.any_of(query_h)
    end
    def is_friend_post(friend)
      if friend==true
        cg_ids = Sns::CustomGroup.any_of({:friend_user_id => Core.profile.id},{:user_id=>Core.profile.id}).map(&:sequence)
        if cg_ids.blank?
          criteria.any_of({:privacy=>"public"},{:privacy=>"friend"})
        else
          query_h = [{:privacy=>"public"},{:privacy=>"friend"}]
          cg_ids.each do |cg|
            query_h << {:privacy=>cg}
          end
          criteria.any_of(query_h)
        end
      else
        criteria.where(:privacy=>"public")
      end
    end
  end
end
