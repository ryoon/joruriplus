# encoding: utf-8
module Sns::Model::Option
  def is_liked?(user=Core.profile)
    ret = self.likes.where(:created_user_id=>user.id)
    return false if ret.blank?
    return true
  end

  def like(user=Core.profile)
    ret = self.likes.where(:created_user_id=>user.id).first
    return nil if ret.blank?
    return ret
  end

  def is_favorited?(user=Core.profile)
    ret = self.favorites.where(:created_user_id=>user.id)
    return false if ret.blank?
    return true
  end
  def favorite(user=Core.profile)
    ret = self.favorites.where(:created_user_id=>user.id).first
    return nil if ret.blank?
    return ret
  end

end
