# encoding: utf-8
module Sns::NewsfeedHelper
  include Sns::Model::Post

  def post_show(str)
    return nil if str.blank?
    str = remove_html_tag(str)
    str = str.gsub(/\r\n|\r|\n/, '<br />')
    str = uri_to_link(str)
    str = mailaddr_to_link(str)
    return nil if str.blank?
    return str.html_safe
  end

  def feed_publiched_members(item)
    custom_group_members = item.custom_group_members
    publiched_members = ""
    if item.privacy == "all" || item.privacy == "public"
      publiched_members = "公開範囲：全ユーザー"
    elsif item.privacy == "group"
      group = Sys::Group.find_by_id(item.pr_group_id)
      publiched_members = "公開範囲：#{group.group_short_name unless group.blank?}"
    else
      unless custom_group_members.blank?
        custom_users = custom_group_members.split(/,/)
        if custom_users.size <= 1
          publiched_members = "公開範囲：#{custom_group_members}"
        else
          users_size = custom_users.size - 1
          publiched_members = "公開範囲：#{custom_users[0]} 他#{users_size}名"
        end
      end
    end
    return publiched_members.html_safe
  end

  def post_br(str)
    return nil if str.blank?
    str = str.gsub(/\r\n|\r|\n/, '<br />')
    return str
  end

  def activity_report(str)
    return nil if str.blank?
    str = str.gsub(/「.*」の/,"")
    return str.html_safe
  end

  def selected_users_show(item)
    ret = item.range_show
    ret = link_to(item.range_show, "#", :class=>"showPublishedUsers", :id=>"showPublished#{item.id}")  if item.is_limited?
    return ret.html_safe
  end

  def custom_users_show_link(publiched_members, item)
    ret = publiched_members
    ret = link_to(publiched_members, "#", :class=>"showCommentPublishedUsers", :id=>"showComentPublished#{item.id}")  if item.is_limited?
    return ret.html_safe
  end

  def convert_for_feed_body(body)
    #テーブルタグは削除
    body.gsub!(/<table[ ].*?>.*?<\/table>/iom) do |m|
      '' #remove
    end
    #imgタグは削除
    body.gsub!(/<img .*?src=".*?".*?>/iom) do |m|
      '' #remove
    end
    #リンクタグは削除
    body.gsub!(/<a .*?href=".*?".*?>/iom) do |m|
      '' #remove
    end
    return body
  end

  def max_sequence(feeds,options={})
    sequences = []
    feeds.each do |f|
      sequences << f.sequence unless f.sequence.blank?
    end
    max = sequences.max
    return max
  end

  def min_sequence(feeds,options={})
    sequences = []
    feeds.each do |f|
      sequences << f.sequence unless f.sequence.blank?
    end
    min = sequences.min
    return min
  end

  def is_liked?(user_ids = [],user_profile=Core.profile)
    return false if user_ids.blank?
    return false if user_ids.index(user_profile.id).blank?
    return true
  end

  def creator_photo(feed_user,item)
    return "/_common/themes/admin/sns/images/sample_small.jpg" if feed_user.blank?
    return feed_user.profile_photo_path(true) if feed_user.user_group.blank?
    if item.created_group_id.blank?
      return feed_user.profile_photo_path(true)
    else
      if item.created_group_id == feed_user.user_group.id
        return feed_user.profile_photo_path(true)
      else
        return "/_common/themes/admin/sns/images/sample_small.jpg"
      end
    end
  end

  def user_profile_page(user)
    return "/_admin" if user.blank?
    return "/_admin/profile/#{user.account}"
  end

end
