# -*- encoding: utf-8 -*-
class Sns::EnqueteOption
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :count, :type=>Integer
  field :user_ids, :type=>Array

  embedded_in :enquete, :class_name=>"Sns::Enquete"

end
