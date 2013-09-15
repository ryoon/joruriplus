# -*- encoding: utf-8 -*-
class Sns::Member
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id
  field :state
  field :sort_no

  referenced_in :user, :class_name=>"Sns::Profile"
  embedded_in :project, :class_name=>"Sns::Project"
  embedded_in :schedule, :class_name=>"Sns::Schedule"

end
