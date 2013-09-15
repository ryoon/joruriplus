# encoding: utf-8
module Sns::Model::Creator

  def set_creator_infomation
    unless Core.user.blank? && Core.user_group.blank?
      self.created_user_name = Core.user.name
      self.created_group_name = Core.user_group.name
      self.created_group_code = Core.user_group.code
      self.created_group_id = Core.user_group.id
    end
  end

  def creator_photo(feed_user)
    return "/_common/themes/admin/sns/images/sample_small.jpg" if feed_user.blank?
    return feed_user.profile_photo_path(true) if feed_user.user_group.blank?
    if self.created_group_id.blank?
      return feed_user.profile_photo_path(true)
    else
      if self.created_group_id == feed_user.user_group.id
        return feed_user.profile_photo_path(true)
      else
        return "/_common/themes/admin/sns/images/sample_small.jpg"
      end
    end
  end

  def creator_name(privacy=nil)
    user_name = self.created_user_name
    group_name = self.created_group_name
    if self.created_user_name.blank? && !self.created_user.blank?
      user_name = self.created_user.name
      group_name = self.created_user.group_name({:s_name=>false})
    end
    if privacy=="all"
      name_str = %Q(<span class="user">（#{user_name}）</span>)
      group_str = %Q(<span class="department">#{group_name}</span>)
      link_str = %Q(#{group_str}#{name_str})
    else
      name_str = %Q(<span class="user">#{user_name}</span>)
      group_str = %Q(<span class="department">（#{group_name}）</span>)
      link_str = %Q(#{name_str}#{group_str})
    end
    return link_str.html_safe
  end

end
