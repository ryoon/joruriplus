# -*- encoding: utf-8 -*-
require 'mime/types'
#require 'shared-mime-info'
class Sns::File
  include Mongoid::Document
  include Mongoid::Timestamps
  include Sns::Model::File
  include Sns::Model::Base
  include Sns::Model::Privacy
  include Sns::Model::Creator

  field :file_name
  field :file_path
  field :file_directory
  field :original_file_name
  field :content_type
  field :file_size
  field :created_user_id
  field :caption
  field :privacy
  field :size
  field :sequence, :type=>Float
  field :is_project, :type=>Integer
  field :project_id
  field :conference_id
  field :pr_group_id
  field :album_id
  field :publised_user_id, :type=>Array
  field :created_user_name
  field :created_group_name
  field :created_group_code
  field :created_group_id, :type=>Integer

  before_create :set_creator_infomation

  referenced_in :album, :class_name=>"Sns::Album"
  referenced_in :created_user, :class_name=>"Sns::Profile"

  referenced_in :project, :class_name=>"Sns::Project"

  after_create :set_group_id

  def set_group_id
    return if self.privacy != "group"
    self.pr_group_id = Core.user_group.id
    self.save(:validate=>false)
  end

  def public_uri
    return nil unless Core
    "/_admin/_files/#{escaped_name}"
  end

  def project_file_path
    return if self.project.blank?
    "/_admin/sns/projects/#{self.project.code}/files/#{self.id}"
  end

  def file_data_save(params, mode,options={})
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
    update_file = Hash::new # 更新時、ファイルがアップロードされていない場合は、既存のファイル情報を継続させる。

    unless file.blank?
      upload_file = file.read
      content_type = file.content_type
      file_size = file.size
      original_file_name = file.original_filename # ファイル名
      extname = File.extname(original_file_name) # 拡張子を抽出
    else
      if mode == :create
        self.errors.add :upload, 'を選択してください。'
      elsif mode == :update
        update_file[:file_path] = self.file_path
        update_file[:file_directory] = self.file_directory
        update_file[:file_name] = self.file_name
        update_file[:file_size] = self.file_size
        update_file[:original_file_name] = self.original_file_name
        update_file[:content_type] = self.content_type
        update_file[:privacy] = par_item[:privacy]
        update_file[:caption] = par_item[:caption]
        update_file[:size] = self.size
        update_file[:pr_group_id] = group_id if par_item[:privacy] == "group"
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
      file = Hash::new
      if options[:file_kind] == :feed
        album_id = album_exist("ニュースフィード",core_profile_id)
      elsif options[:photo_kind] == :note
        album_id = album_exist("ノート",core_profile_id)
      else
        album_id = par_item[:album_id]
      end
      if options[:is_project]
        project = Sns::Project.find(:first, :conditions=>{:_id=>options[:project_id]})
        if project
          album_id = album_exist("「#{project.title}」のファイル",core_profile_id,{:is_project=>options[:is_project],:project_id=>options[:project_id]})
        else
          album_id = nil
        end
        file[:project_id] = options[:project_id]
        file[:is_project] = 1
      end
      file[:album_id] = album_id
      file[:privacy] = par_item[:privacy]
      sequense_str = "#{format('%08d', self.sequence)}"
      filename =  "#{sequense_str}#{extname}"
      mime_type = MIME::Types.type_for(filename)
      if mime_type.blank?
        file[:content_type] = content_type
      else
        file[:content_type] = mime_type[0].to_s
      end
      file[:original_file_name] = original_file_name
      file[:size]=file.size
      dir = sequense_str.gsub(/(.*)(..)(..)(..)$/, '\1/\2/\3/\4/\1\2\3\4')
      directory = "/upload/sns/file/#{dir}/"
      upload_name = "#{sequense_str}.dat"
      file[:file_name] = filename
      file[:file_directory] = directory
      file[:created_user_id] = core_profile_id
      file[:privacy]=par_item[:privacy]
      file[:caption] = par_item[:caption]
      file_path = %Q(#{directory}#{upload_name})
      file[:file_path] = file_path
      file[:file_size] = file_size
      upload_path = Rails.root.to_s
      upload_path += '/' unless upload_path.ends_with?('/')
      upload_path += "#{file_path}"
      unless mkdir_for_file upload_path
        # ディレクトリが作成できない
        self.errors.add :upload, 'ディレクトリが作成できません。'
      end

      if self.errors.size == 0
        #実ファイルを保存
        File.delete(upload_path) if File.exist?(upload_path)
        File.open(upload_path, 'wb') { |f| f.write(upload_file) }
        self.update_attributes(file)
        self.save
        return true
      else
        return false
      end
    elsif save_flg && file.blank? && mode == :update
      # 既存データを保存
      self.update_attributes(update_file)
      self.save
      return true
    else
      return false
    end
  end

  def album_exist(name,core_profile_id,options={})
    if options[:is_project]
      album = Sns::Album.find(:first, :conditions=>{:project_id => options[:project_id], :kind=>"file"})
    else
      album = Sns::Album.find(:first, :conditions=>{:created_user_id => core_profile_id, :name=>name, :kind=>"file"})
    end
    if album.blank?
      params = {:kind=>"file",:created_user_id => core_profile_id, :name=>name, :state=>"public",:is_project=>options[:is_project],:project_id=>options[:project_id]}
      new_album = Sns::Album.create(params)
      profile_album_id = new_album.id
    else
      profile_album_id = album.id
    end
    return profile_album_id
  end


  def destroy_file
    src = "#{Rails.root.to_s}#{self.file_directory}"
    FileUtils.rm_rf(src)
    rescue => e
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
