class Sns::ActivityConfig
  include Mongoid::Document
  include Mongoid::Timestamps

  field :project
  field :project_thread
  field :project_comment
  field :project_member
  field :project_schedule
  field :project_activity
  field :project_activity_comment
  field :proposal
  field :note
  field :schedule
  field :comment
  field :update_limit, :type=>Integer

  embedded_in :profile, :class_name=>"Sns::Profile"
end
