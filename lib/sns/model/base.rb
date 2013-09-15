# encoding: utf-8
module Sns::Model::Base

  def sequence_number
    collection_name = self.collection.name
    item = Sns::Sequence.find(:first, :conditions=>{:name=>collection_name})
    if item.blank?
      item = Sns::Sequence.new
      item.name = collection_name

    end
    item.inc(:sequence, 1)
    item.save
    sequence_id = item.sequence
    self.sequence = sequence_id
  end

  def get_sequence_number
    collection_name = self.collection.name
    item = Sns::Sequence.find(:first, :conditions=>{:name=>collection_name})
    if item.blank?
      item = Sns::Sequence.new
      item.name = collection_name
      item.sequence = 0
    end
    sequence_id = item.sequence + 1
    return sequence_id
  end

  def fit_digit(value, digit, str='0')
    str * (digit - value.to_s.size) + value.to_s rescue value.to_s
  end

  def is_editable?(profile=Core.profile,user=Core.user)
    return true if user.has_auth?(:manager)
    return true if self.created_user_id ==  profile.id
    return false
  end

  def is_creator?(profile=Core.profile)
    return true if self.created_user_id == profile.id
    return false
  end

  def is_deletable?(profile=Core.profile,user=Core.user,group=Core.user_group)
    return true if user.has_auth?(:manager)
    return true if self.group_id ==  group.id if self.privacy=="all"
    return true if self.created_user_id ==  profile.id
    return false
  end
end
