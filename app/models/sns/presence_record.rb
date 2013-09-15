class Sns::PresenceRecord
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id
  field :presence_at, :type => Time, :allow_nil => true

  referenced_in :user, :class_name=>"Sns::Profile"


end
