# encoding: utf-8
class Sns::Favorite
  include Mongoid::Document
  include Mongoid::Timestamps

  field :kind
  field :created_user_id
  field :parent_id
  field :name
  field :account

  embedded_in :post, :class_name=>"Sns::Post"
  embedded_in :thread, :class_name=>"Sns::Thread"
  referenced_in :created_user, :class_name=>"Sns::Profile"
end
