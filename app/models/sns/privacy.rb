class Sns::Privacy
  include Mongoid::Document
  include Mongoid::Timestamps

  field :base_info
  field :history
  field :address
  field :skill
  field :interest
  field :pr

  embedded_in :profile, :class_name=>"Sns::Profile"
end
