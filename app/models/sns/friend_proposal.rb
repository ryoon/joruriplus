# encoding: utf-8
class Sns::FriendProposal
  include Mongoid::Document
  include Mongoid::Timestamps
  include Sns::Model::Activity
  include Sns::Model::Post
  include Sys::Lib::Mail::Address

  field :fr_user_id
  field :to_user_id
  field :body
  field :reply_body
  field :state
  field :kind
  field :project_id
  field :schedule_id


  referenced_in :fr_user, :class_name=>"Sns::Profile"
  referenced_in :to_user, :class_name=>"Sns::Profile"

  referenced_in :project, :class_name=>"Sns::Project"
  referenced_in :schedule, :class_name=>"Sns::Schedule"

  after_create :feed_notice

  after_destroy :destroy_feed

  def feed_notice(options=nil)
    member_list = [self.to_user.id]
    project_id = nil
    is_project = 0
    parent_title = ""
    if self.project
      project_id = self.project.id
      parent_title = self.project.title
      is_project = 1
    end
    if self.kind=="friend"
      post_kind = ["proposal"]
      post_body = %Q(#{Core.profile.name}さんから<a href="/_admin/sns/friend_proposals?kind=friend" target="_blank">友達追加申請</a>が届きました。)
    elsif self.kind=="project"
      post_kind = ["project_member"]
      post_body = %Q(#{Core.profile.name}さんから<a href="/_admin/sns/friend_proposals?kind=invite" target="_blank">#{parent_title}</a>への招待が届きました。)
    elsif self.kind=="project_manager"
      post_kind = ["project_member"]
      post_body = %Q(#{Core.profile.name}さんから<a href="/_admin/sns/friend_proposals?kind=invite" target="_blank">#{parent_title}</a>の管理メンバーへの招待が届きました。)
    elsif self.kind=="project_join"
      post_kind = ["project_member"]
      post_body = %Q(#{Core.profile.name}さんから<a href="/_admin/sns/friend_proposals?kind=join" target="_blank">プロジェクト参加希望申請</a>が届きました。)
    elsif self.kind=="project_leave"
      post_kind = ["project_member"]
      post_body = %Q(#{Core.profile.name}さんから<a href="/_admin/sns/friend_proposals?kind=leave" target="_blank">プロジェクト退会申請</a>が届きました。)
    else
      return
    end
    feed_post("notice", post_body,post_kind,member_list,project_id,is_project,{:proposal_id=>self.id})
    if self.kind == "project"
      send_project_mail(self.fr_user,self.to_user,self.project,"invite")
    elsif self.kind == "project_manager"
      send_project_mail(self.fr_user,self.to_user,self.project,"invite")
    elsif self.kind=="project_leave"
      send_project_mail(self.fr_user,self.to_user,self.project,"leave")
    elsif self.kind=="project_join"
      send_project_mail(self.fr_user,self.to_user,self.project,"join")
    end
  end

  def destroy_feed
    proposal_feed = Sns::Post.where({:proposal_id=>self.id})
    proposal_feed.destroy_all unless proposal_feed.blank?
  end

  def index_body(length=200)
    return nil if self.body.blank?
    str = self.body
    str = remove_html_tag(str)
    unless str.blank?
      str = str.slice(0,length)

      str = "#{str}…" if self.body.length > length
    end
    return str
  end

  def display_body(length=200)
    return nil if self.body.blank?
    str = self.body
    str = remove_html_tag(str)
    unless str.blank?
      str = str.slice(0,length)
      str = str.gsub(/\r\n|\r|\n/, '<br />')
      str = "#{str}…" if self.body.length > length
    end
    return str
  end

  def show_reply(length=200)
    return nil if self.reply_body.blank?
    str = self.reply_body
    str = remove_html_tag(str)
    unless str.blank?
      str = str.slice(0,length)
      str = str.gsub(/\r\n|\r|\n/, '<br />')
      str = "#{str}…" if self.reply_body.length > length
    end
    return str
  end

  def state_select
    select = [["未読","unread"],["既読","read"],["承認","recognized"],["却下","refused"]]
    return select
  end

  def state_show
    state_select.each {|a| return a[0] if a[1] == state }
    return nil
  end

  def kind_select
    select = [
    ["プロジェクト","project"],
    ["プロジェクト","project_manager"],
    ["友達申請", "friend"],
    ["スケジュール参加依頼", "schedule"],
    ["プロジェクト退会申請", "project_leave"],
    ["プロジェクト参加希望申請", "project_join"]
    ]
  end

  def kind_show
    kind_select.each {|a| return a[0] if a[1] == kind }
    return nil
  end

  def recognize_proposal
    fr_friend = Sns::Friend.find(:first, :conditions=>{:user_id=>self.fr_user_id})
    if fr_friend.blank?
      fr_friend = Sns::Friend.new
      fr_friend.user_id = self.fr_user_id
      fr_arr = []
      fr_arr << self.to_user_id
    else
      fr_arr = fr_friend.friend_user_id
      fr_arr << self.to_user_id
    end
    fr_arr = fr_arr.uniq
    fr_friend.friend_user_id = fr_arr
    if fr_friend.deleted_friend_id.blank?
      fr_deleted_friend = []
    else
      fr_deleted_friend = fr_friend.deleted_friend_id
    end
    fr_deleted_friend.delete(self.to_user_id)
    fr_deleted_friend = fr_deleted_friend.uniq
    fr_friend.deleted_friend_id = fr_deleted_friend
    fr_friend.save

    to_friend = Sns::Friend.find(:first, :conditions=>{:user_id=>self.to_user_id})
    if to_friend.blank?
      to_friend = Sns::Friend.new
      to_friend.user_id = self.to_user_id
      to_arr = []
      to_arr << self.fr_user_id
    else
      to_arr = to_friend.friend_user_id
      to_arr << self.fr_user_id
    end
    to_arr = to_arr.uniq
    to_friend.friend_user_id = to_arr
    if to_friend.deleted_friend_id.blank?
      to_deleted_friend = []
    else
      to_deleted_friend = to_friend.deleted_friend_id
    end
    to_deleted_friend.delete(self.fr_user_id)
    to_deleted_friend = to_deleted_friend.uniq
    to_friend.deleted_friend_id = to_deleted_friend
    to_friend.save
    post_body = "#{self.to_user.name}さんが友達追加申請を承認しました。"
    feed_post("notice", post_body,["proposal","friend"],[self.fr_user_id],nil,0,{:proposal_id=>self.id})
  end


##プロジェクトの招待申請

  def save_with_rels(params, mode, options={})
    users = options[:members]
    managers = options[:managers]
    if managers.blank? && (mode == :create || mode == :manager)
      self.errors.add_to_base "管理者が登録されていません。"
    end
    if users.blank? && mode == :proposal
      self.errors.add_to_base "ユーザーが登録されていません。"
    end
    if users.size > 200
      self.errors.add_to_base "メンバーは200人以上登録できません。"
    end if mode != :manager && !users.blank?
    project = Sns::Project.find(:first, :conditions=>{:_id=>params[:project_id]})
    if project.blank?
      self.errors.add_to_base "プロジェクトのデータが正しくありません。"
    else
      members_count = project.members
      self.errors.add_to_base "メンバーは200人以上登録できません。" if members_count.size >= 200 unless members_count.blank?
    end
    self.body = params[:item][:body]
    message= params[:item][:body]
    managers_id = []
    if self.errors.size > 0
      return false
    else
      if mode == :create || mode == :manager
        managers.each do |manager|
          next if project.is_manager?(manager)
          next unless project.is_penging?(manager, "project_manager")
          next unless project.is_penging?(manager, "project")
          if manager.id == Core.profile.id
            new_user = Sns::ProjectMember.new({:user_id=>manager.id, :state=>"enabled",:sort_no=>manager.sort_no})
            project.managers << new_user
          else
            manager_params = {
                :fr_user_id => Core.profile.id,
                :to_user_id => manager.id,
                :body => message,
                :state => "unread",
                :project_id => project.id,
                :kind=>"project_manager"
           }
            manager_invite = Sns::FriendProposal.new(manager_params)
            manager_invite.save
            managers_id << manager.id
          end
        end
      end

      if mode != :manager && !users.blank?
        users.each do |user|
          next if project.is_member?(user)
          next unless project.is_penging?(user, "project")
          next unless project.is_penging?(user, "project_manager")
          if user.id == Core.profile.id
            new_user = Sns::Member.new({:user_id=>user.id, :state=>"enabled", :sort_no=>user.sort_no})
            project.members << new_user
          else
            unless managers_id.blank?
              next if managers_id.index(user.id)
            end
            member_params = {
                :fr_user_id => Core.profile.id,
                :to_user_id => user.id,
                :body => message,
                :state => "unread",
                :project_id => project.id,
                :kind=>"project"
           }
            member_invite = Sns::FriendProposal.new(member_params)
            member_invite.save
          end
        end
      end
      is_creator_member = project.is_member?(Core.profile)
      is_creator_manager = project.is_manager?(Core.profile)
      if is_creator_member == false and  is_creator_manager == true
        new_user = Sns::Member.new({:user_id=>Core.profile.id, :state=>"enabled", :sort_no=>Core.profile.sort_no})
        project.members << new_user
      end
      return true
    end
  end

  def recognize_notice

    return if self.kind=="friend" or self.kind=="schedule"

    to_friend = self.to_user
    return if to_friend.blank?

    fr_friend = self.fr_user
    return if fr_friend.blank?

    config = manager_config
    to_project = Sns::Project.find(:first, :conditions=>{:_id=>self.project_id})

    return if to_project.blank?
    send_project_mail(fr_friend,to_friend,to_project,"recog") if fr_friend && config[:invite_recog]=="on"
    new_user = Sns::Member.new({:user_id=>to_friend.id, :state=>"enabled", :sort_no=>to_friend.sort_no})
    if self.kind == "project"
      to_project.members << new_user unless to_project.is_member?(to_friend)
    else
      to_project.members << new_user unless to_project.is_member?(to_friend)
      new_manager = Sns::ProjectMember.new({:user_id=>to_friend.id, :state=>"enabled",:sort_no=>to_friend.sort_no})
      to_project.managers << new_manager  unless to_project.is_manager?(to_friend)
      other_proposal = Sns::FriendProposal.where(:project_id=>to_project.id, :to_user_id=>to_friend.id, :kind=>"project", :state=>"unread").first
      unless other_proposal.blank?
        other_proposal.state = "recognized"
        other_proposal.save
      end
    end
    to_project.save
  end

  def leave_project(state)
    return if self.kind != "project_leave"
    fr_friend = self.fr_user
    return if fr_friend.blank?
    to_friend = self.to_user
    return if to_friend.blank?
    to_project = self.project
    return if to_project.blank?
    member_list = [self.to_user.id, self.fr_user.id]
    kind = "leave_refuse"
    if state =="recognized"
      kind = "leave_recog"
      leave_manager = to_project.managers.where(:user_id => fr_friend.id).first
      leave_manager.destroy unless leave_manager.blank?
      leave_member = to_project.members.where(:user_id => fr_friend.id).first
      leave_member.destroy unless leave_member.blank?
    end
    send_project_mail(fr_friend,to_friend,to_project,kind)
    other_proposals = Sns::FriendProposal.where(:project_id=>to_project.id, :fr_user_id=>fr_friend.id, :kind=>"project_leave", :_id.ne=>self.id)
    other_proposals.each do |p|
      member_list << p.to_user.id
      p.state = state
      p.save
    end
    post_body = %Q(#{fr_friend.name}さんの<a href="/_admin/sns/friend_proposals?kind=project" target="_blank">プロジェクトの退会申請</a>を#{self.state_show}しました。)
    feed_post("notice", post_body,["project_member"],member_list,project_id,1)
  end


  def join_project(state)
    return if self.kind != "project_join"
    fr_friend = self.fr_user
    return if fr_friend.blank?
    to_friend = self.to_user
    return if to_friend.blank?
    to_project = self.project
    return if to_project.blank?
    if state =="recognized" && !to_project.is_join?(fr_friend)
      new_member = Sns::Member.new({:user_id=>fr_friend.id, :state=>"enabled",:sort_no=>fr_friend.sort_no})
      to_project.members << new_member
      to_project.save
      post_body =  %Q(メンバー更新：<a href="/_admin/sns/projects/#{to_project.code}" target="_blank">「#{to_project.title}」</a>に参加しました。)
      feed_post("project", post_body,["project"],[self.id],to_project.id,1,{:created_user=>fr_friend})
    end
    other_proposals = Sns::FriendProposal.where(:project_id=>to_project.id, :fr_user_id=>fr_friend.id, :kind=>"project_join", :_id.ne=>self.id)
    other_proposals.each do |p|
      p.state = state
      p.save
    end
    send_project_mail(to_friend,fr_friend,to_project,"join_recog")
  end

  def send_project_mail(fr_user,to_user,project,kind)
    mail_to = ""
    config = manager_config

    site_uri = ""
    begin
      rails_env = ENV['RAILS_ENV']
      site = YAML.load_file('config/core.yml')
      site_uri = site[rails_env]['uri']
    rescue
    end
    site_uri += "/" unless site_uri.ends_with?('/')
    mail_fr = system_mail_addr
    if kind == "invite"
      mail_to = to_user.mail_addr
      subject = "プロジェクトから招待がきています"
      message = "#{fr_user.name}（#{fr_user.group_name({:s_name=>false})}）さんから「#{project.title}」への招待が来ています。\n以下のURLを確認してください。\n"
      message +="#{site_uri}_admin/sns/friend_proposals/#{self.id}"
      return if config[:invite] != "on"
    elsif kind == "recog"
      mail_to = fr_user.mail_addr
      subject = "招待が受理されました"
      message = "#{to_user.name}（#{to_user.group_name({:s_name=>false})}）さんが「#{project.title}」に参加しました。\n以下のURLを確認してください。\n"
      message +="#{site_uri}_admin/sns/projects/#{project.code}"
      return if config[:invite_recog] != "on"
    elsif kind =="leave"
      mail_to = to_user.mail_addr
      subject = "プロジェクト退会申請を提出します"
      message = "#{fr_user.name}（#{fr_user.group_name({:s_name=>false})}）さんが「#{project.title}」の退会申請を提出しました。\n以下のURLを確認してください。\n"
      message +="#{site_uri}_admin/sns/friend_proposals?kind=leave"
      return if config[:leave] != "on"
    elsif kind =="leave_recog"
      mail_to = fr_user.mail_addr
      subject = "プロジェクト退会申請が受理されました"
      message = "#{to_user.name}（#{to_user.group_name({:s_name=>false})}）さんが「#{project.title}」への退会申請を却下しました。"
      return if config[:leave_recog] != "on"
    elsif kind =="leave_refuse"
      mail_to = fr_user.mail_addr
      subject = "プロジェクト退会申請が却下されました"
      message = "#{to_user.name}（#{to_user.group_name({:s_name=>false})}）さんが「#{project.title}」への退会申請を受理しました。"
      return if config[:leave_refuse] != "on"
    elsif kind =="join"
      mail_to = to_user.mail_addr
      subject = "プロジェクト参加希望申請を提出します"
      message = "#{fr_user.name}（#{fr_user.group_name({:s_name=>false})}）さんが「#{project.title}」の参加希望申請を提出しました。\n以下のURLを確認してください。\n"
      message +="#{site_uri}_admin/sns/friend_proposals?kind=join"
      return if config[:join] != "on"
    elsif kind =="join_recog"
      mail_to = fr_user.mail_addr
      subject = "プロジェクト参加希望申請が受理されました"
      message = "#{to_user.name}（#{to_user.group_name({:s_name=>false})}）さんが「#{project.title}」への参加希望申請を承認しました。"
      return if config[:join_recog] != "on"
    else
      return
    end
    return if mail_to.blank?
    message += "\n\nこのメールアドレスは送信専用です。"
    Sys::Lib::Mail::Base.deliver_default(mail_fr, mail_to, subject, message)
  end


  class << self
    def k_call(code)
    @kind = case code
    when "invite"
      query_h = {:kind.in=>["project", "project_manager"]}
    when "leave"
      query_h = {:kind=>"project_leave"}
    when "schedule"
      query_h = {:kind=>"schedule"}
    when "friend"
      query_h = {:kind=>"friend"}
    when "join"
      query_h = {:kind=>"project_join"}
    else
      return
    end
      criteria.where(query_h)
    end
  end

end
