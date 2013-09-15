class Sns::MailNotice
  include Mongoid::Document
  include Mongoid::Timestamps

  field :proposal
  field :recognized
  field :invite
  field :invite_recog
  field :project
  field :leave
  field :leave_recog
  field :leave_refuse
  field :join
  field :join_recog

  embedded_in :profile, :class_name=>"Sns::Profile"
end
