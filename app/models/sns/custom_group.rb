# encoding: utf-8
class Sns::CustomGroup
  include Mongoid::Document
  include Mongoid::Timestamps
  include Sns::Model::Base

  field :user_id
  field :friend_user_id, :type => Array
  field :name
  field :sequence, :type=>Float

  referenced_in :user, :class_name=>"Sns::Profile"

  validates_presence_of :name, :message=>"が、入力されていません。"
  validates_presence_of :friend_user_id, :message=>"が、選択されていません。"

  before_create :sequence_number

  def display_title
    return "確認する" if self.name.blank?
    return self.name
  end

  def self.custom_friends(sequence_id, c_user_id)
    c_group = Sns::CustomGroup.find(:first, :conditions=>{:sequence => sequence_id, :user_id=>c_user_id})
    return nil if c_group.blank?
    return nil if c_group.friend_user_id.blank?
    c_user = Sns::Profile.any_in(:_id=>c_group.friend_user_id).asc(:updated_at)
    ret = ""
    ret = "#{c_group.user.name}," unless c_group.user.blank?
    return nil if c_user.blank?
    c_user.each_with_index do |c, n|
      ret += "#{c.name}"
      ret += "," unless n == c_user.length - 1
    end
    return ret
  end

  def self.custom_name(sequence_id, c_user_id)
    c_group = Sns::CustomGroup.find(:first, :conditions=>{:sequence => sequence_id, :user_id=>c_user_id})
    return nil if c_group.blank?
    return "カスタム（#{c_group.name}）"
  end


  def self.remove_user(user_id)
    my_groups = Sns::CustomGroup.find(:all, :conditions=>{:friend_user_id=>user_id})
    if my_groups
      my_groups.each do |g|
        g_users = g.friend_user_id
        g_users.delete(user_id)
        g.friend_user_id = g_users
        g.save
      end
    end
  end

  def self.is_member?(sequence_id, user_id)
    c_group = Sns::CustomGroup.find(:first, :conditions=>{:sequence => sequence_id, :friend_user_id=>user_id})
    return false if c_group.blank?
    return true
  end

end
