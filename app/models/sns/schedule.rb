# encoding: utf-8
class Sns::Schedule
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia
  include Sns::Model::Base
  include Sns::Model::Activity
  include Sns::Model::Creator
  include Sys::Lib::Mail::Address

  field :created_user_id
  field :creator_group_id
  field :owner_id
  field :owner_gid
  field :title_category_id, :type=>Integer
  field :title
  field :place
  field :is_public
  field :project_id
  field :memo
  field :st_at, :type=>Time
  field :ed_at, :type=>Time
  field :sequence, :type=>Float
  field :created_user_name
  field :created_group_name
  field :created_group_code
  field :created_group_id, :type=>Integer

  embeds_many :members, :class_name=>"Sns::Member"

  referenced_in :created_user, :class_name=>"Sns::Profile"
  referenced_in :owner, :class_name=>"Sns::Profile"
  referenced_in :project, :class_name=>"Sns::Project"

  after_destroy :destroy_feed
  before_create :sequence_number,:set_creator_infomation

  def editable?(user = Core.profile)
    return true if user.id == self.created_user.id
  end

  def save_with_rels(params, mode, options={})
    par_item = params[:item]
    #adds = ::JsonParser.new.parse(params[:item]['schedule_users_json'])
    users = params[:user_id]
#    if mode==:create && users.blank?
    if users.blank?
      self.errors.add_to_base "参加者が登録されていません。"
    end
    project = Sns::Project.find(:first, :conditions=>{:_id=>params[:item][:project_id]})
    if project.blank?
      self.errors.add_to_base "プロジェクトのデータが正しくありません。"
    end
    if params[:c_date].blank?
      self.errors.add_to_base "日付が指定されていません。"
    end
    if self.st_at >= self.ed_at
      self.errors.add :ed_at, "は、開始時刻より後の時刻を指定してください。"
    end
    if params[:item][:title].blank?
      self.errors.add :title, "を入力してください。"
    end
    if self.errors.size > 0
      return false
    else
      #adds 差分更新
      users = users.dup
      new_users = []
      old_users = self.members
      old_users.each_with_index{|old_user, x|
        use = 0
        users.each_with_index{|user, y|
          if old_user.user_id.to_s == user.to_s
            users.delete_at(y)
            use = 1
          end
        }
        old_user.destroy if use == 0
      }
      users.each_with_index{|user, y|
        new_user = Sns::Member.new({:user_id=>user, :state=>"unread"})
        new_user.state = "join" if new_user.user_id == Core.profile.id
        new_users << new_user
        self.members << new_user
      }
      self.save
      if mode==:create
        invite_member = self.members
      else
        invite_member = new_users
      end
      schedule_users = add_user_post(invite_member) if invite_member
      schedule_post({:schedule_users=>schedule_users})
      proposal_mail(invite_member) if invite_member
      return true
    end
  end

  def show_uri(options={})
    "/_admin/sns/projects/#{self.project.code}/schedules/#{self.id}"
  end

  def add_user_post(schedule_users)
    parent_project =  self.project
    member_list = []
    schedule_users.each do |u|
      next if u.user_id == Core.profile.id
      member_list << u.user_id
      new_proposal = Sns::FriendProposal.create({
        :kind=>"schedule",
        :fr_user_id=>Core.profile.id,
        :to_user_id=>u.user_id,
        :body=>%Q(「#{parent_project.title}」のイベント<a href="#{show_uri}" target="_blank">#{self.title}</a>に参加しませんか？),
        :state=>"unread",
        :project_id=>parent_project.id,
        :schedule_id=>self.id
      })
    end
    post_body =%Q(#{Core.profile.name}さんからイベントの招待がありました。<br /><a href="#{show_uri}" target="_blank">>>確認する</a>)
    feed_post("notice",post_body,["schedule"], member_list,parent_project.id,1,{:schedule_id=>self.id}) unless member_list.blank?
    return member_list
  end

  def schedule_post(options={})
    return if self.project.blank?
    parent_project =  self.project
    post_body =  %Q(「#{parent_project.title}」の<a href="#{show_uri}" target="_blank">スケジュール</a>が更新されました。)
    feed_post("project",post_body,["project_schedule"], [self.id],parent_project.id,1,{:schedule_id=>self.id,:exclude_id=>options[:schedule_users]})
  end

  def display_body(length=30)
    ret = %Q(開催日：#{self.st_at.strftime('%Y年%m月%d日')}<br />開始時間：#{self.st_at.strftime('%H：%M')}-終了時間：#{self.ed_at.strftime('%H：%M')}<br />)
    ret += %Q(件名：#{self.title}<br />場所：#{self.place}<br />メモ：#{self.memo})
    return ret
  end

  def proposal_mail(invite_member)
    schedule_users = invite_member
    parent_project =  self.project
    mail_fr = system_mail_addr
    subject = "「#{parent_project.title}」更新通知"
    message = %Q(「#{parent_project.title}」のイベントに参加しませんか？\n下記URLをご確認ください。\n)
    site_uri = ""
    begin
      rails_env = ENV['RAILS_ENV']
      site = YAML.load_file('config/core.yml')
      site_uri = site[rails_env]['uri']
    rescue
    end
    site_uri += "/" unless site_uri.ends_with?('/')
    message += "#{site_uri}#{show_uri}"
    config = manager_config
    schedule_users.each do |u|
      p_user = u.user
      mail_to = p_user.mail_addr
      next if config[:project] != "on"
      next if mail_to.blank?
      Sys::Lib::Mail::Base.deliver_default(mail_fr, mail_to, subject, message) if p_user.notice_config[:project]=="on"
    end
  end

  def category_title
    if self.title_category_id.blank?
      ret = self.title
    else
      ret = %Q([#{self.title_category_show}]#{self.title})
    end
  end

  def title_category_select
    select = [
      ["会議" ,100],
      ["出張" ,200],
      ["研修" ,300],
      ["休暇" ,400],
      ["仕事集中タイム" ,500],
      ["来客対応" ,600],
      ["重要イベント" ,700],
      ["期限日" ,800],
      ["注意" ,900],
      ["県議会関係" ,950],
      ["予定あり" ,1000],
      ["その他１" ,1100],
      ["その他２" ,1200]
    ]
    return select
  end

  def schedule_join_members
    join_members = self.members
    join = []
    absence = []
    unread = []

    join_members.each do |m|
      case m.state
      when "join"
        join << m
      when "absence"
        absence << m
      else
        unread << m
      end
    end
    ret = {:join=>join, :absence=>absence,:unread=>unread}
    return ret
  end

  def title_category_show
    title_category_select.each {|a| return a[0] if a[1] == title_category_id }
    return nil
  end

  def self.participant_select
    select = [["未確認","unread"],["参加","join"],["不参加","absence"]]
    return select
  end

  def self.participant_state(p_state)
    participant_select.each {|a| return a[0] if a[1] == p_state }
    return nil
  end

  def is_join?(user=Core.profile)
    cnt = self.members.where(:user_id => user.id)
    return true unless cnt.blank?
    return false
  end

  def user_state(user=Core.profile)
    cnt = self.members.where(:user_id => user.id).first
    if cnt.blank?
      return ""
    else
      return cnt.state
    end
  end

  def destroy_feed
    Sns::Post.destroy_all(:conditions=>{:schedule_id=>self.id})
  end
end
