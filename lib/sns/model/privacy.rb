# encoding: utf-8
module Sns::Model::Privacy

  def range_select
    select = [["限定公開","friend"],
    ["所属通知","group"],
    ["公開","public"],
    ["非公開","closed"],
    ["全庁通知","all"],
    ["通知","notice"],
    ["プロジェクト","project"],
    ["プロジェクト","project_activity"],
    ["限定公開","select"]
    ]
    return select
  end


  def is_limited?
    return false if self.privacy == "public"
    return false if self.privacy == "all"
    return false if self.privacy == "notice"
    return false if self.privacy == "project"
    return false if self.privacy == "project_activity"
    return true
  end

  def range_show
    return "限定公開（友達）" if self.created_user_id == Core.profile.id and privacy == "friend"
    return "限定公開（ワンタイム）" if self.created_user_id == Core.profile.id and privacy == "select"
    range_select.each {|a| return a[0] if a[1] == privacy }
    return Sns::CustomGroup.custom_name(privacy,self.created_user_id) if self.created_user_id == Core.profile.id
    return "限定公開"
  end

  def published_user_name
    return nil if self.privacy!="select"
    return nil if self.publised_user_id.blank?
    ret = ""
    ret = "#{self.created_user.name}," unless self.created_user.blank?
    published_users = Sns::Profile.where(:_id.in=>self.publised_user_id, :_id.ne=>self.created_user_id)
    published_users.each_with_index do |c, n|
      ret += "#{c.name}"
      ret += "," unless n == published_users.length - 1
    end
    return ret
  end


  def custom_group_members
    if self.privacy == "friend"
      creator_friends = Sns::Friend.where(:user_id => self.created_user_id).first
      return creator_friends.friend_names if creator_friends
    elsif self.privacy == "select"
      return self.published_user_name
    else
      range_select.each {|a| return nil if a[1] == privacy }
      cg = Sns::CustomGroup.custom_friends(self.privacy, self.created_user_id)
      return cg if cg
    end
    return nil
  end

  def auth_check(profile=Core.profile,user=Core.user)
    return true if self.created_user_id == profile.id
    return true if user.has_auth?(:manager)
    return true if self.privacy=="all" or  self.privacy=="public"
    return false if self.privacy=="group" and profile.user_group.blank?
    return true if self.privacy=="group" and self.pr_group_id == profile.user_group.id
    return true if self.privacy=="friend" and profile.is_friend?(self.created_user)
    if self.privacy=="select"
      return false if self.publised_user_id.blank?
      return true unless self.publised_user_id.index(profile.id).blank?
      return false
    end
    if self.privacy=~/project/
      project_check = self.project
      return true if project_check.blank?
      return true if project_check.publish == "public"
      return true if self.project.is_member?  if project_check.publish == "closed"
    end
    return Sns::CustomGroup.is_member?(self.privacy, profile.id)  if self.privacy.to_i != 0
    return false
  end

end
