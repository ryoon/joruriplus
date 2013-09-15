# encoding: utf-8
class Sns::Profile
  include Mongoid::Document
  include Mongoid::Timestamps

  #アカウント情報
  field :name
  field :kana
  field :account
  field :user_id, :type => Integer
  field :photo_path
  field :thumb_photo_path
  field :state
  field :message
  field :sort_no


  #基本情報
  field :sex , :type => Integer
  field :bloodtype
  field :birthday, :type => Date, :allow_nil => true

  #連絡先
  field :address
  field :phone_number
  field :mobile_number
  field :mail_addr
  field :ind_addr
  field :facebook_name
  field :addr_01

  #特技
  field :job_skill
  field :license
  field :circle

  #興味関心
  field :interest
  field :thought
  field :research_group

  #自己PR
  field :self_introduce
  field :resolution
  field :program


  embeds_one :office,:class_name=>"Sns::Office"
  embeds_one :privacy, :class_name=>"Sns::Privacy"
  embeds_one :notice, :class_name=>"Sns::MailNotice"
  embeds_one :a_config, :class_name=>"Sns::ActivityConfig"

  #references_one :friend, :class_name=>"Sns::Friend", :dependent => :destroy

  after_destroy :destroy_links

  def state_select
    select = [["有効","enabled"],["無効","disabled"]]
    return select
  end

  def state_show
    state_select.each {|a| return a[0] if a[1] == state }
    return nil
  end

  def publish_select
    #select = [["すべてのユーザー","public"],["友達つながり","preclosed"],["友達","closed"]]
    select = [["すべてのユーザー","public"],["友達","friend"]]
    return select
  end


  def self.publish_show(value)
    #select = [["すべてのユーザー","public"],["友達つながり","preclosed"],["友達","closed"]]
    select = [["すべてのユーザー","public"],["友達","friend"]]
    select.each {|a| return a[0] if a[1] == value }
    return nil
  end

  def notice_select
    select = [["通知する","on"],["通知しない","off"]]
    return select
  end


  def self.notice_show(value)
    select = [["通知する","on"],["通知しない","off"]]
    select.each {|a| return a[0] if a[1] == value }
    return nil
  end

  def sex_select
    select = [["男性",1],["女性",2]]
    return select
  end

  def bloodtype_select
    select = [["A型","A"],["B型","B"],["AB型","AB"],["O型","O"]]
    return select
  end

  def sex_show
    sex_select.each {|a| return a[0] if a[1] == sex }
    return nil
  end

  def bloodtype_show
    bloodtype_select.each {|a| return a[0] if a[1] == bloodtype }
    return nil
  end

  def profile_photo_path(thumb=false)
    if thumb == false
      if photo_path.blank?
        path = "/_common/themes/admin/sns/images/sample.jpg"
      else
        path = photo_path
      end
    else
      if thumb_photo_path.blank?
        path = "/_common/themes/admin/sns/images/sample_small.jpg"
      else
        path = thumb_photo_path
      end
    end
    return path
  end

  def profile_uri
    ret = "/_admin/profile/#{self.account}"
    return ret
  end

  def message_show
    return "　" if self.message.blank?
    return self.message
  end

  def activity_config
    if self.a_config.blank?
      ret = {
      :project_thread=>"on",
      :project_comment=>"on",
      :project_member=>"on",
      :schedule=>"on",
      :proposal=>"on",
      :note=>"on",
      :project_schedule=>"on",
      :comment=>"on",
      :project=>"on",
      :project_activity=>"on",
      :project_activity_comment=>"on",
      :update_limit=>15
      }
    else
      ret = self.a_config
    end
    return ret
  end
  def post_update_limit
    return 15 if self.a_config.blank? || self.a_config.update_limit.blank?
    return self.a_config.update_limit.to_i
  end

  def privacy_config
    if self.privacy.blank?
      setting = {:post => "public",:file=>"public",:base_info=>"friend",
        :history=>"public",:address=>"friend",:skill=>"public",:interest=>"public",:pr=>"public"}
    else
      setting = self.privacy
   end
    return setting
  end

  def privacy_state(key)
    settings = privacy_config
    return "すべてのユーザー" if settings[key]=="public"
    return "友達"
  end

  def notice_config
    if self.notice.blank?
      setting = {:proposal => "off",:recognized=>"off", :invite=>"off",
      :invite_recog=>"off",:project=>"on",:leave=>"on",:leave_recog=>"on",:leave_refuse=>"on"}
    else
      setting = self.notice
   end
    return setting
  end

  def projects_show(options={})
    projects = Sns::Project.any_of({"members.user_id"=>self.id},{"managers.user_id"=>self.id})
    if options[:select]
      ret = []
      projects.each do |p|
        ret << [p.id, p.title]
      end if projects
    else
      ret = projects
    end
    return ret
  end

  def friends_select
    item = Sns::Friend.find(:first, :conditions=>{:user_id=>self.id})
    ret = []
    unless item.blank?
      friends_ids = item.friend_user_id
      friends = Sns::Profile.any_in(:_id=>friends_ids)
      friends.each do |f|
        ret << [f.name , f.id]
      end
    end
    return ret
  end

  def get_friend_info
    item = Sns::Friend.find(:first, :conditions=>{:user_id=>self.id})
    if item.blank?
      friends_ids = []
      friends_ids << self.id
      return [nil , friends_ids]
    else
      friends_ids = item.friend_user_id
      friends = Sns::Profile.any_in(:_id=>friends_ids)
      friends_ids << self.id
      return [friends, friends_ids]
    end
  end

  def show_friends
    item = Sns::Friend.find(:first, :conditions=>{:user_id=>self.id})
    if item.blank?
      return nil
    else
      friends_ids = item.friend_user_id
      friends = Sns::Profile.any_in(:_id=>friends_ids)
      return friends
    end
  end

  def friend_link(item, opt = {})
    if item.blank?
      return nil
    else
      if opt[:friend_ids].blank?
        friends_ids = item.friend_user_id
      else
        friends_ids = opt[:friend_ids]
      end
      return nil if friends_ids.blank?
      friends = Sns::Profile.any_in(:_id=>friends_ids)
      return nil if friends.blank?
      link_ids = []
      friends.each do |f|
        fr_lnk = Sns::Friend.find(:first, :conditions=>{:user_id=>f.id})
        lnk_id = fr_lnk.friend_user_id
        link_ids += lnk_id
      end
      return link_ids
    end
  end

  def common_friend(user,my_friends,opt={})
    num = 0
    return num if my_friends.blank?
    user_friends = Sns::Friend.find(:first, :conditions=>{:user_id=>user.id})
    return num if user_friends.blank?
    my_friends_ids = my_friends.friend_user_id
    user_friends_ids = user_friends.friend_user_id
    user_friends_ids.each do |u|
      if !(my_friends_ids.index(u).blank?)
        num += 1
      end
    end
    return num
  end

  def get_common_friends(user,my_friends,opt={})
    ids = []
    return nil if my_friends.blank?
    user_friends = Sns::Friend.find(:first, :conditions=>{:user_id=>user.id})
    return nil if user_friends.blank?
    my_friends_ids = my_friends.friend_user_id
    user_friends_ids = user_friends.friend_user_id
    user_friends_ids.each do |u|
      if !(my_friends_ids.index(u).blank?)
        ids << u
      end
    end
    return nil if ids.blank?
    common_users = Sns::Profile.where(:_id.in=>ids)
    return common_users
  end

  def is_friend?(user, options={})
    return true if self.id == user.id
    if options[:custom_sequence]
      friends = Sns::CustomGroup.where(:user_id=>self.id).where(:friend_user_id=>user.id).where(:sequence=>options[:custom_sequence])
    else
      friends = Sns::Friend.where(:user_id=>self.id).where(:friend_user_id=>user.id)
    end
    return false if friends.blank?
    return true
  end


  def is_pending?(user=Core.profile)
    cnt = Sns::FriendProposal.where(:kind=>"friend", :state.in=>["unread","read"], :fr_user_id=>user.id, :to_user_id=>self.id)
    return false if cnt.blank?
    return true
  end

  def member_limit?
    friend = Sns::Friend.where(:user_id=>self.id).first
    return false if friend.blank?
    return false if friend.friend_user_id.size <= 500
    return true
  end

  def public_auth(content,is_friend)
    return true if self.id == user.id
    return true if is_friend==true
    privacy = self.privacy_config
    return true if privacy[content]=="public"
    return false
  end

  def user_group
    user = Sys::User.find_by_id(self.user_id)
    return nil if user.blank?
    groups = user.groups
    return nil if groups.blank?
    return groups[0]
  end

  def group_name(options={:s_name=>true})
    user = Sys::User.find_by_id(self.user_id)
    return nil if user.blank?
    groups = user.groups
    return nil if groups.blank?
    if options[:s_name] == true
      ret = groups[0].group_short_name
    else
      ret = groups[0].name
    end
    return ret
  end

  def get_custom_group
    c_groups = Sns::CustomGroup.where(:user_id=>self.id)
    return c_groups
  end

  def self.get_user_select(g_id=nil,all=nil, options = {})
    #_conditions="state='enabled'"
    selects = []
    selects << ['すべて',0] if all=='all'
    group_selects = []
    group_selects << ['すべて',0] if all=='all'
    if g_id.blank?
      u = Core.user
      g = u.groups[0]
      gid = g.id
    else
      gid = g_id
    end
    #LDAP同期ユーザのみ表示の仕様を追加 :option = 1 ならLDAP同期ユーザのみとする
    f_ldap = ''
    f_ldap = '1' if options[:ldap] == 1
    conditions="state='enabled' and sys_users_groups.group_id = #{gid}" if f_ldap.blank?
    conditions="state='enabled' and sys_users_groups.group_id = #{gid} and sys_users.ldap = 1" unless f_ldap.blank?
    order = "sys_users.sort_no"
    users_select = Sys::User.find(:all,:conditions=>conditions,:select=>"id,account,name",
      :order=>order,:joins=>'left join sys_users_groups on sys_users.id = sys_users_groups.user_id')
    selects += users_select.map{|user| user.id }
    return nil if selects.blank?
    return selects if options[:user_select] == 1
    if options[:exclude_id]
      group_profiles = Sns::Profile.order_by([:sort_no, :asc]).any_in("user_id" => selects).excludes("_id"=>options[:exclude_id])
    else
      group_profiles = Sns::Profile.order_by([:sort_no, :asc]).any_in("user_id" => selects)
    end
    return group_profiles if options[:profile_select] == 1

    return group_selects if group_profiles.blank?
    if options[:select]
      group_selects += group_profiles.collect{|x| [x.name, x.id]}
    else
      group_selects += group_profiles.map{|prof| prof.id }
    end
    return group_selects
  end

  def project_select
    ret = []
    projects = Sns::Project.where("members.user_id"=>self.id)
    projects.each do |p|
      ret << p.id
    end unless projects.blank?
    return ret
  end


  def destroy_links
    Sns::Friend.destroy_all(:conditions=>{:user_id=>self.id})
    Sns::Friend.remove_user(self.id)
    Sns::CustomGroup.destroy_all(:conditions=>{:user_id=>self.id})
    Sns::CustomGroup.remove_user(self.id)
    p_members = Sns::Project.where("members.user_id"=>self.id)
    p_members.each do |p|
      member = p.members.where({:user_id=>self.id}).first
      member.destroy if member
      manager = p.managers.where({:user_id=>self.id}).first
      manager.destroy if manager
    end
  end

  class << self
    def word_query(word)
      search_words = word.to_s.split(/[ 　]+/)
      target = []
      search_words.each do |m|
        str = m.gsub(/\./,'\.')
        target << /.*#{str}.*/
      end
      query_h = [
        {:name.all=>target},
        {:kana.all=>target},
        {:address.all=> target,"privacy.address"=>"public"},
        {:phone_number.all=> target,"privacy.address"=>"public"},
        {:mobile_number.all=> target,"privacy.address"=>"public"},
        {:mail_addr.all=> target},
        {:job_skill.all=> target,"privacy.skill"=>"public"},
        {:license.all=> target,"privacy.skill"=>"public"},
        {:circle.all=> target,"privacy.skill"=>"public"},
        {:interest.all=> target,"privacy.interest"=>"public"},
        {:thought.all=> target,"privacy.interest"=>"public"},
        {:research_group.all=> target, "privacy.interest" => "public"},
        {:self_introduce.all=> target,"privacy.pr"=>"public"},
        {:resolution.all=> target,"privacy.pr"=>"public"},
        {:program.all=> target,"privacy.pr"=>"public"},
        {:ind_addr.all=> target,"privacy.address"=>"public"},
      ]
      criteria.any_of(query_h)
    end
  end

end