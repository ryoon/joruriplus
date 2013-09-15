# encoding: utf-8
class Sns::Office
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :start_at, :type => Date, :allow_nil => true
  field :end_at, :type => Date, :allow_nil => true
  field :offitial_position
  field :assigned_job
  field :extension
  field :remarks

  embedded_in :profile, :class_name=>"Sns::Profile"
end
