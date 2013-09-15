class Sns::Sequence
  include Mongoid::Document

  field :name
  field :sequence, :type=>Float

end
