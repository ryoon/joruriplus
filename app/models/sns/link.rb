# encoding: utf-8
class Sns::Link
  include Mongoid::Document
  include Mongoid::Timestamps
  include Sns::Model::Base
  include Sns::Model::Privacy

  field :url
  field :thumbnail_path
  field :created_user_id
  field :privacy
  field :sequence, :type=>Float
  field :publised_user_id, :type=>Array

  validates_uniqueness_of :url, :scope=>:created_user_id, :message=>"はすでに登録されています。"

  before_create :sequence_number
  referenced_in :created_user, :class_name=>"Sns::Profile"

end
