# -*- encoding: utf-8 -*-
class Sns::Enquete
  include Mongoid::Document
  include Mongoid::Timestamps
  include Sns::Model::Base
  include Sns::Model::Privacy
  include Sns::Model::Creator

  field :created_user_id
  field :sequence, :type=>Float
  field :privacy
  field :pr_group_id
  field :publised_user_id
  field :is_project, :type=>Integer
  field :project_id
  field :total
  field :created_user_name
  field :created_group_name
  field :created_group_code
  field :created_group_id, :type=>Integer

  before_create :sequence_number,:set_creator_infomation
  after_create :set_group_id

  referenced_in :created_user, :class_name=>"Sns::Profile"

  embeds_many :select_options,:class_name=>"Sns::EnqueteOption"

  def set_group_id
    return if self.privacy != "group"
    self.pr_group_id = Core.user_group.id
    self.save(:validate=>false)
  end

end
