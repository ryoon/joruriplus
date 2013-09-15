# encoding: utf-8
class Sns::Comment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :body
  field :created_user_id
  field :like_user_id, :type=>Array
  field :created_user_name
  field :created_group_name
  field :created_group_code
  field :created_group_id, :type=>Integer

  embedded_in :post, :class_name=>"Sns::Post"
  referenced_in :created_user, :class_name=>"Sns::Profile"

end
