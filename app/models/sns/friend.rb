# encoding: utf-8
class Sns::Friend
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id
  field :friend_user_id, :type => Array
  field :deleted_friend_id, :type=>Array

  referenced_in :user, :class_name=>"Sns::Profile"

  def friend_names
    return nil if self.friend_user_id.blank?
    friend_users = Sns::Profile.where(:_id.in=>self.friend_user_id)
    ret = ""
    ret = "#{self.user.name}," unless self.user.blank?
    friend_users.each_with_index do |f, n|
      ret += "#{f.name}"
      ret += "," unless n == friend_users.length - 1
    end unless friend_users.blank?
    return ret
  end

  def self.remove(to_user_id,options={})
    if options[:fr_user_id]
      fr_user = Sns::Profile.find(options[:fr_user_id])
      return false if fr_user.blank?
    else
      fr_user = Core.profile
    end

    to_user = Sns::Profile.find(to_user_id)
    return false if to_user.blank?

    fr_friend = Sns::Friend.find(:first, :conditions=>{:user_id => fr_user.id})
    return false if fr_friend.blank?
    to_friend = Sns::Friend.find(:first, :conditions=>{:user_id => to_user.id})
    return false if to_friend.blank?
    fr_arr = fr_friend.friend_user_id
    fr_arr.delete(to_user.id)
    fr_friend.friend_user_id = fr_arr
    if fr_friend.deleted_friend_id.blank?
      fr_deleted_friend = []
    else
      fr_deleted_friend = fr_friend.deleted_friend_id
    end
    fr_deleted_friend << to_friend.user_id
    fr_deleted_friend = fr_deleted_friend.uniq
    to_friend.deleted_friend_id = fr_deleted_friend
    fr_friend.save

    to_arr = to_friend.friend_user_id
    to_arr.delete(fr_user.id)
    to_friend.friend_user_id = to_arr
    if to_friend.deleted_friend_id.blank?
      to_deleted_friend = []
    else
      to_deleted_friend = to_friend.deleted_friend_id
    end
    to_deleted_friend << fr_friend.user_id
    to_deleted_friend = to_deleted_friend.uniq
    to_friend.deleted_friend_id = to_deleted_friend
    to_friend.save

    fr_c_groups = Sns::CustomGroup.where(:user_id=>fr_user.id,:friend_user_id=>to_user.id)
    fr_c_groups.each do |g|
      fr_users = g.friend_user_id
      next if fr_users.blank?
      fr_users.each_with_index{|f, i|
        if f==to_user.id
          fr_users.delete_at(i)
        end
      }
      g.friend_user_id = fr_users
      g.save
    end unless fr_c_groups.blank?


    to_c_groups = Sns::CustomGroup.where(:user_id=>to_user.id,:friend_user_id=>fr_user.id)
    to_c_groups.each do |g|
      to_users = g.friend_user_id
      next if to_users.blank?
      to_users.each_with_index{|f, i|
        if f==fr_user.id
          to_users.delete_at(i)
        end
      }
      g.friend_user_id = to_users
      g.save(:validate=>false)
    end unless to_c_groups.blank?

    return true
  end


  def self.remove_user(user_id)
    my_friends = Sns::Friend.find(:all, :conditions=>{:friend_user_id=>user_id})
    if my_friends
      my_friends.each do |g|
        g_users = g.friend_user_id
        g_users.delete(user_id)
        g.friend_user_id = g_users
        g.save(:validate=>false)
      end
    end
  end

end
