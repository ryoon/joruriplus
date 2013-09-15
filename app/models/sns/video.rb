# encoding: utf-8
class Sns::Video
  include Mongoid::Document
  include Mongoid::Timestamps
  include Sns::Model::Base
  include Sns::Model::Privacy
  include Sns::Model::Creator

  field :url
  field :caption
  field :created_user_id
  field :privacy
  field :sequence, :type=>Float
  field :width, :type=>Integer
  field :height, :type=>Integer
  field :is_project, :type=>Integer
  field :project_id
  field :pr_group_id
  field :album_id
  field :publised_user_id, :type=>Array
  field :created_user_name
  field :created_group_name
  field :created_group_code
  field :created_group_id, :type=>Integer

  referenced_in :album, :class_name=>"Sns::Album"

  before_create :sequence_number,:set_creator_infomation
  referenced_in :created_user, :class_name=>"Sns::Profile"

  after_create :set_group_id

  def set_group_id
    return if self.privacy != "group"
    self.pr_group_id = Core.user_group.id
    self.save(:validate=>false)
  end

  def album_exist(name,core_profile_id,options={})
    if options[:is_project]
      album = Sns::Album.find(:first, :conditions=>{:project_id => options[:project_id], :kind=>"video"})
    else
      album = Sns::Album.find(:first, :conditions=>{:created_user_id => core_profile_id, :name=>name, :kind=>"video"})
    end
    if album.blank?
      params = {:kind=>"video",:created_user_id => core_profile_id, :name=>name, :state=>"public",:is_project=>options[:is_project],:project_id=>options[:project_id]}
      new_album = Sns::Album.create(params)
      profile_album_id = new_album.id
    else
      profile_album_id = album.id
    end
    return profile_album_id
  end

  def thumb_path
    return nil if self.url.blank?
    ret = url.gsub(/(.*)(\/show$)/, '\1')
    ret = ret + "/thumbnail"
    return ret
  end
  def post_body(length=30)
    return nil if self.caption.blank?
    result = self.caption.slice(0,length)
    result += "…" if caption.length > length
    return result
  end


  class << self
    #検索用criteria
    def post_user(id)
      criteria.where(:created_user_id => id)
    end

    def p_call(friend_ids)
      friend_hash = [{ :privacy => "friend", :created_user_id=>friend_ids }, { :privacy => "friend", :created_user_id=>Core.profile.id}]
      if friend_ids
        query_h = [
        { :privacy => "public" },
        { :privacy => "closed",:created_user_id=>Core.profile.id },
        {:privacy=>"group", :pr_group_id=>Core.user_group.id},
        friend_hash
        ]
      else
        query_h = [
        { :privacy => "public" },
        { :privacy => "closed",:created_user_id=>Core.profile.id },
        {:privacy=>"group", :pr_group_id=>Core.user_group.id},]
      end
      cg_ids = Sns::CustomGroup.any_of({:friend_user_id => Core.profile.id},{:user_id=>Core.profile.id}).map(&:sequence)
      cg_ids.each do |cg|
        query_h << {:privacy=>cg}
      end unless cg_ids.blank?
      criteria.any_of(query_h)
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
