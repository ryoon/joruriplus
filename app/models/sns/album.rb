# -*- encoding: utf-8 -*-
class Sns::Album
  include Mongoid::Document
  include Mongoid::Timestamps
  include Sns::Model::Base
  include Sns::Model::Privacy
  include Sns::Model::Creator
  before_create :set_creator_infomation

  after_destroy :clear_photos

  field :name
  field :kind
  field :created_user_id
  field :state
  field :privacy
  field :is_project, :type=>Integer
  field :project_id
  field :created_user_name
  field :created_group_name
  field :created_group_code
  field :created_group_id, :type=>Integer

  before_create :set_creator_infomation

  referenced_in :created_user, :class_name=>"Sns::Profile"
  referenced_in :project, :class_name=>"Sns::Project"

  def clear_photos
    photos = Sns::Photo.destroy_all(:conditions => { :album_id => self.id })
  end

  class << self
    #検索用criteria
    def post_user(id)
      criteria.where(:created_user_id => id)
    end
    def p_call
      cg_ids = Sns::CustomGroup.any_of({:friend_user_id => Core.profile.id},{:user_id=>Core.profile.id}).map(&:sequence)
      if cg_ids.blank?
        criteria.any_of({ :privacy => "public" }, { :privacy => "friend" },{ :privacy => "closed",:created_user_id=>Core.profile.id })
      else
        query_h = [{ :privacy => "public" }, { :privacy => "friend" },{ :privacy => "closed",:created_user_id=>Core.profile.id }]
        cg_ids.each do |cg|
          query_h << {:privacy=>cg}
        end
        criteria.any_of(query_h)
      end
    end
    def is_friend_post(friend)
      if friend==true
        cg_ids = Sns::CustomGroup.any_of({:friend_user_id => Core.profile.id},{:user_id=>Core.profile.id}).map(&:sequence)
        if cg_ids.blank?
          criteria.any_of({:privacy=>"public"},{:privacy=>"friend"})
        else
          query_h = [{:privacy=>"public"},{:privacy=>"friend"}]
          cg_ids.each do |cg|
            query_h << {:privacy=>cg}
          end
          criteria.any_of(query_h)
        end
      else
        criteria.where(:privacy=>"public")
      end
    end
  end

end
