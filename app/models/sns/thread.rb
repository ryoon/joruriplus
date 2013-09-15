# -*- encoding: utf-8 -*-
class Sns::Thread
  include Mongoid::Document
  include Mongoid::Timestamps
  #include Mongoid::Timestamps::Timeless
  include Mongoid::Paranoia
  include Sns::Model::Base
  include Sns::Model::Activity
  include Sns::Model::Option
  include Sns::Model::Creator
  include Sns::Model::Post
  include Sns::Model::Reminder
  include Sys::Lib::Mail::Address

  field :project_id
  field :project_sequence, :type=>Float
  field :sequence, :type=>Float
  field :title
  field :body
  field :created_user_id
  field :contents, :type=>Array
  field :conf_sequence, :type=>Float
  field :kind
  field :parent_id
  field :comment_size, :type=>Integer
  field :last_updated_at, :type=>Time
  field :doc_updated_at, :type=>Time
  field :created_user_name
  field :created_group_name
  field :created_group_code
  field :created_group_id, :type=>Integer

  before_create :sequence_number, :set_last_updated,:set_creator_infomation
  after_update :update_reminder

  referenced_in :project, :class_name=>"Sns::Project"

  referenced_in :parent, :class_name=>"Sns::Thread"
  references_many :childs, :class_name=>"Sns::Thread", :order=> :created_at

  referenced_in :created_user, :class_name=>"Sns::Profile"
  embeds_many :likes,:class_name=>"Sns::Like"
  embeds_many :favorites,:class_name=>"Sns::Favorite"

  after_create :project_post, :set_conf_sequence
  after_destroy :destroy_feed, :destroy_files, :detroy_comment, :destroy_option_feed

  def set_last_updated
    self.last_updated_at = Time.now
    self.doc_updated_at = Time.now
  end

  def last_doc_update
    return self.updated_at if self.doc_updated_at.blank?
    return self.doc_updated_at
  end

  def comments
    return Sns::Thread.where(:parent_id=>self.id).asc(:created_at)
  end

  def comment_size_show
    return 0 if self.comment_size.blank?
    return self.comment_size
  end

  def project_post
    return if self.project.blank?
    parent_project =  self.project

    if self.kind=="comment"
      post_body_kind = "コメント"
      post_kind = ["project_comment"]
      thread_uri = "/_admin/sns/projects/#{parent_project.code}/conferences/#{self.parent_id}"
      kind_post = %Q(target="_blank">電子会議室（#{self.title}）</a>にコメントがありました。<br />#{})
      content_id = [self.id, ["thread",self.parent_id]]
    else
      post_body_kind = "投稿"
      post_kind = ["project_thread"]
      thread_uri = "/_admin/sns/projects/#{parent_project.code}/conferences/#{self.id}"
      kind_post = %Q(target="_blank">電子会議室に「#{self.title}」</a>が投稿されました。<br />#{})
      content_id = [self.id]
    end
    post_body = %Q(「#{parent_project.title}」の<a href="#{thread_uri}" )
    post_body += kind_post
    feed_post("project",post_body,post_kind, content_id,parent_project.id,1)
    project_mail
  end

  def project_mail
    config = manager_config
    return false if config[:project]!="on"
    parent_project = Sns::Project.where(:_id=>self.project_id).first
    return false if parent_project.blank?
    members = parent_project.members
    mail_fr = system_mail_addr
    site_uri=""
    begin
      rails_env = ENV['RAILS_ENV']
      site = YAML.load_file('config/core.yml')
      site_uri = site[rails_env]['uri']
    rescue
    end
    site_uri += "/" unless site_uri.ends_with?('/')
    if self.kind=="comment"
      post_uri = "#{site_uri}/_admin/sns/projects/#{parent_project.code}/conferences/#{self.parent_id}"
    else
      post_uri = "#{site_uri}/_admin/sns/projects/#{parent_project.code}/conferences/#{self.id}"
    end
    members.each do |m|
      user = m.user
      next if user.blank?
      next if user.id == Core.profile.id
      mail_to = user.mail_addr
      next if  mail_to.blank?
      subject = "#{parent_project.title}更新通知"
      message = %Q(#{self.created_user.name}さんが#{parent_project.title}の会議室を更新しました。下記URLをご確認ください。\n#{post_uri})
      message += "\n\nこのメールアドレスは送信専用です。"
      Sys::Lib::Mail::Base.deliver_default(mail_fr, mail_to, subject, message)
    end unless members.blank?
  end


  def set_conf_sequence
    last_no = Sns::Thread.where(:sequence.lt => self.sequence, :project_id=>self.project_id, :kind=>"thread").desc(:sequence).first
    set_no = 1
    if last_no
      set_no = last_no.conf_sequence.to_i + 1
    end
    self.conf_sequence = set_no
    self.save(:validate=>false)
  end

  def doc_uri(options={})
    if options[:parent_project]
      p_project = options[:parent_project]
    else
      p_project = self.project
    end
    return "" if p_project.blank?
    if self.kind=="thread"
      p_uri = "/_admin/sns/projects/#{p_project.code}/conferences/#{self.id}" unless project.blank?
    else
      p_uri = "/_admin/sns/projects/#{p_project.code}/conferences/#{self.parent_id}#conference#{self.id}" unless project.blank?
    end
    return p_uri
  end

  def display_body(length=30)
    return nil if self.body.blank?
    str = self.body
    line_str = []
    str.each_line {|line|
      line_str << line
    }
    if line_str.length > 3
      str = "#{line_str[0]}#{line_str[1]}#{line_str[2]}"
    end
    unless str.blank?
      str = str.slice(0,length)
      str = str.strip
      str = remove_html_tag(str)
      str = str.gsub(/\r\n|\r|\n/, '<br />')
    end
    str = uri_to_link(str)
    str = mailaddr_to_link(str)
    if line_str.blank?
      str += "…<br /><a href='#{doc_uri}' target='_blank'>続きはこちら>></a>" if self.body.length > length
    else
      if line_str.length > 3
        str += "…<br /><a href='#{doc_uri}' target='_blank'>続きはこちら>></a>" if line_str.length > 3 or !self.contents.blank?
      else
        str += "…<br /><a href='#{doc_uri}' target='_blank'>続きはこちら>></a>" if self.body.length > length or !self.contents.blank?
      end
    end
    return str
  end


  def post_body
    return nil if self.body.blank?
    str = self.body.gsub(/\r\n|\r|\n/, '<br />')
    str = uri_to_link(str)
    str = mailaddr_to_link(str)
    return str
  end

  def destroy_files
    photo_ids = []
    file_ids = []
    video_ids = []
    self.contents.each do |c|
      if c[0]=="photo"
        photo_ids << c[1]
      elsif c[0]=="file"
        file_ids << c[1]
      elsif c[0]=="video"
        video_ids << c[1]
      end
    end
    Sns::Photo.destroy_all(:conditions=>{:_id.in=>photo_ids, :project_id=>self.project_id}) unless photo_ids.blank?
    Sns::File.destroy_all(:conditions=>{:_id.in=>file_ids, :project_id=>self.project_id}) unless file_ids.blank?
    Sns::Video.destroy_all(:conditions=>{:_id.in=>video_ids, :project_id=>self.project_id}) unless video_ids.blank?
  end

  def detroy_comment
    Sns::Thread.destroy_all(:conditions=>{:parent_id=>self.id})
  end

  def destroy_feed
    Sns::Post.destroy_all(:conditions=>{:kind=>"project",:content_id=>self.id})
    if self.kind=="thread"
      Sns::Post.destroy_all(:conditions=>{:kind=>"project_thread",:content_id=>self.id})
      Sns::Post.destroy_all(:conditions=>{:kind=>"project",:content_id=>["thread",self.id]})
      Sns::Post.destroy_all(:conditions=>{:kind=>"project_comment",:content_id=>["thread",self.id]})
    else
      Sns::Post.destroy_all(:conditions=>{:kind=>"project_comment",:content_id=>self.id})
    end
  end

  def destroy_option_feed
    Sns::Post.destroy_all(:conditions=>{:content_id=>["like_thread",self.id],:kind=>"like"})
    Sns::Post.destroy_all(:conditions=>{:content_id=>["fav_thread",self.id],:kind=>"favorite"})
  end

 class << self
    #検索用criteria
    def show_titles(project_id,fav)
      if fav=="0"
        criteria.where(:project_id=>project_id, :kind=>"thread")
      else
        criteria.where(:project_id=>project_id, :kind=>"thread", "favorites.created_user_id"=>Core.profile.id)
      end
    end

    def call_star(profile=Core.profile)
      criteria.where("favorites.created_user_id"=>profile.id)
    end
    def word_query(word,project_ids)
      search_words = word.to_s.split(/[ 　]+/)
      target = []
      search_words.each do |m|
        str = m.gsub(/\./,'\.')
        target << /.*#{str}.*/
      end
      query_h = [
        {:title.all=>target, :project_id.in=>project_ids},
        {:body.all=>target, :project_id.in=>project_ids},
      ]
      criteria.any_of(query_h)
    end

  end
end
