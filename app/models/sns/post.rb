# encoding: utf-8
class Sns::Post
  include Mongoid::Document
  include Mongoid::Timestamps
  include Sns::Model::Base
  include Mongoid::Paranoia
  include Sns::Model::Option
  include Sns::Model::Privacy
  include Sns::Model::Creator
  include Sns::Model::Post
  include Sns::Model::Reminder

  field :text
  field :created_user_id
  field :privacy, :type=>Float
  field :kind, :type=>Array
  field :sequence, :type=>Float
  field :is_project, :type=>Integer
  field :project_id
  field :pr_group_id
  field :photo_ids, :type=>Array
  field :file_ids, :type=>Array
  field :video_ids, :type=>Array
  field :content_id, :type=>Array
  field :publised_user_id, :type=>Array
  field :exclude_user_id, :type=>Array
  field :proposal_id
  field :group_id, :type=>Integer
  field :schedule_id
  field :enquete_id
  field :created_user_name
  field :created_group_name
  field :created_group_code
  field :created_group_id, :type=>Integer

  before_create :sequence_number,:set_creator_infomation, :set_group_id
  after_create :set_reminder
  after_destroy :destroy_files, :destroy_option_feed, :destroy_reminder

  referenced_in :created_user, :class_name=>"Sns::Profile"
  referenced_in :project, :class_name=>"Sns::Project"
  referenced_in :proposal, :class_name=>"Sns::FriendProposal"
  referenced_in :enquete, :class_name=>"Sns::Enquete"
  embeds_many :comments,:class_name=>"Sns::Comment"
  embeds_many :likes,:class_name=>"Sns::Like"
  embeds_many :favorites,:class_name=>"Sns::Favorite"

  def destroy_files
    photo_ids = self.photo_ids
    file_ids = self.file_ids
    video_ids = self.video_ids
    enquete_id = self.enquete_id
    Sns::Photo.destroy_all(:conditions=>{:_id.in=>photo_ids}) unless photo_ids.blank?
    Sns::File.destroy_all(:conditions=>{:_id.in=>file_ids}) unless file_ids.blank?
    Sns::Video.destroy_all(:conditions=>{:_id.in=>video_ids}) unless video_ids.blank?
    Sns::Enquete.destroy_all(:conditions=>{:_id=>enquete_id}) unless enquete_id.blank?
  end

  def destroy_option_feed
    Sns::Post.destroy_all(:conditions=>{:content_id=>["like_post",self.id],:kind=>"like"})
    Sns::Post.destroy_all(:conditions=>{:content_id=>["like_report",self.id],:kind=>"like"})
    Sns::Post.destroy_all(:conditions=>{:content_id=>["fav_post",self.id],:kind=>"favorite"})
    Sns::Post.destroy_all(:conditions=>{:content_id=>["fav_report",self.id],:kind=>"favorite"})
  end

  def set_group_id
    self.pr_group_id = Core.user_group.id if self.privacy == "group"
    self.group_id  = Core.user_group.id
  end

  def activity_kind
    ["project","project_thread","project_comment","project_member",
    "proposal","note","project_schedule","schedule",
    "comment","project_activity","activity_comment",
    "like","favorite"]
  end

  def is_activity?
    return true if self.privacy=="project_activity"
    return false if self.kind.blank?
    select = activity_kind
    ret = false
    if self.kind.instance_of?(Array)
      self.kind.each do |s|
        ret = true  if select.index(s)
      end
    else
      ret = true  if select.index(self.kind)
    end
    return ret
  end

  def is_project_report?
    return false if self.privacy=="project_activity"
    return false if self.kind.blank?
    return true if self.kind.index("project_thread")
    return true if self.kind.index("project_comment")
    return false
  end


  def activity_body
    ret = ""
    if self.privacy=="project_activity"
      return self.activity_comment_body if self.kind[0]=="activity_comment"
      return self.project_activity_body
    end
    p_project = self.project
    if self.kind[0]=="project_thread"
      item = Sns::Thread.where(:_id=>self.content_id[0]).first
    elsif self.kind[0]=="project_comment"
      item = Sns::Thread.where(:_id=>self.content_id[0]).first
      if self.content_id[1].blank?
        parent_id = ""
      else
        parent_id = self.content_id[1][1]
      end
    elsif self.kind[0]=="proposal"
      item = Sns::FriendProposal.where(:_id=>self.proposal_id).first
    elsif self.kind[0]=="project_member"
      item = Sns::FriendProposal.where(:_id=>self.proposal_id).first
    elsif self.kind[0]=="schedule"
      if self.schedule_id.blank?
        item = nil
      else
        item = Sns::Schedule.where(:_id=>self.schedule_id).first
      end
    end
    ret = ""
    if self.kind[1].blank?
      ret = item.display_body(100) unless item.blank?
    else
      ret = item.show_reply unless item.blank? if self.kind[1]=="friend"
    end
    return nil if ret.blank?
    unless self.kind[0]=="project_thread" || self.kind[0]=="project_comment"
      ret = uri_to_link(ret)
      ret = mailaddr_to_link(ret)
    end
    #ret += "<br /><a href='#{doc_uri}' target='_blank'>>>続く</a>" unless doc_uri.blank?
    return ret.html_safe
  end

  def doc_uri
    if self.privacy=="project_activity" && !self.project.blank?
      "/_admin/sns/projects/#{self.project.code}/reports/#{self.id}"
    else
      "/_admin/sns/posts/#{self.id}"
    end
  end

  def activity_comment_body(length=100)
    return nil if self.content_id.blank?
    return nil if self.content_id[1].blank?
    return nil if !self.content_id[1].instance_of?(Array)
    return nil if self.content_id[1][1].blank?
    original_post = Sns::Post.where(:_id=>self.content_id[1][1]).first
    return nil if original_post.blank?
    comment = original_post.comments.where(:_id=>self.content_id[0][1]).first
    return nil if comment.body.blank?
    str = post_to_doc_link(comment.body,original_post.doc_uri, length)
    return str.html_safe
  end

  def project_activity_body(length=100)
    return nil if self.text.blank?
    str = post_to_doc_link(self.text,doc_uri, length)
    return str.html_safe
  end

  def is_contents_blank?
    return false if !self.photo_ids.blank?
    return false if !self.file_ids.blank?
    return false if !self.video_ids.blank?
    return true
  end

  def project_post
    ret = ""
    if self.kind[0]=="project_thread"
      item = Sns::Thread.where(:_id=>self.content_id[0]).first
    elsif self.kind[0]=="project_comment"
      item = Sns::Speak.where(:_id=>self.content_id[0]).first
    end
    ret = item.display_body(100) unless item.blank?
    return ret
  end

 def privacy_class
   classes = [['public','open'],['friend','limit'],['select','limit'],['notice','inform'],
   ['group','unitInform'],['project','project'],['all','all'],['project_activity','project']]
   custom_class = 'limit'
   custom_class = 'custom' if self.created_user_id == Core.profile.id
   class_str = classes.assoc(self.privacy)
   class_str ? class_str[1] : custom_class
 end

  #
  class << self
    #検索用criteria
    def post_user(id)
      criteria.where(:created_user_id => id)
    end

    def user_ids(ids=[])
      criteria.any_in("created_user_id" => ids)
    end

    def normal_post
      query_h = [
      { :privacy => "friend", :kind.ne=>"note" },
      { :privacy => "select", :kind.ne=>"note" },
      { :privacy => "all", :kind.ne=>"note" },
      { :privacy => "closed", :kind.ne=>"note" },
      { :privacy => "group", :kind.ne=>"note" },
      ]
      cg_ids = Sns::CustomGroup.all
      cg_ids.each do |cg|
        query_h << {:privacy=>cg.sequence, :kind.ne=>"note"}
      end unless cg_ids.blank?
      criteria.any_of(query_h)
    end

    def k_call(category)
      if category =="news" ||  category =="newsfeed"
        criteria.where(:created_user_id=>Core.profile.id, :privacy.ne=>"notice")
      elsif category=="photo"
        criteria.where({:photo_ids.exists=>true,:photo_ids.ne=>[],:is_project.ne=>1})
      elsif category=="file"
        criteria.where({:file_ids.exists=>true,:file_ids.ne=>[],:is_project.ne=>1})
      elsif category=="video"
        criteria.where({:video_ids.exists=>true,:video_ids.ne=>[],:is_project.ne=>1})
      elsif category=="enquete"
        criteria.where({:enquete_id.exists=>true,:enquete_id.ne=>"",:is_project.ne=>1})
      elsif category=="favorite"
        criteria.where("favorites.created_user_id"=>Core.profile.id)
      else
        criteria.where(:kind=>category,:is_project.ne=>1)
      end
    end

    def public_stream(kind="public",options={})
      activity_config = Core.profile.activity_config
      if activity_config[:note]=="on"
        if kind=="group"
          cond = {:privacy=> kind, :pr_group_id=>Core.user_group.id}
        else
          cond = {:privacy=> kind}
        end
      else
        if kind=="group"
          cond = {:privacy=> kind, :pr_group_id=>Core.user_group.id,:kind.ne=>"note"}
        else
          cond = {:privacy=> kind,:kind.ne=>"note"}
        end
      end
      if options[:fav]=="1"
        criteria.where(cond).where("favorites.created_user_id"=>Core.profile.id)
      else
        criteria.where(cond)
      end
    end

    def custom_call(friend_ids,project_ids,options={})
      query_h = [{ :privacy => "friend", :created_user_id.in=>friend_ids, :kind.ne=>"note" }]
      query_h << { :privacy => "select", :created_user_id.in=>friend_ids, :publised_user_id=>Core.profile.id, :kind.ne=>"note" }
      activities = ["project_thread","project_comment", "project_member","proposal","note","schedule","project_schedule"]
      activity_config = Core.profile.activity_config
      project_activity = []
      activities.each do |x|
        next if activity_config[x.to_sym]!="on"
        if x =~ /project/
          project_activity << x unless x =~ /member/
          query_h  << {:kind=>x, :content_id=>Core.profile.id, :created_user_id.in=>friend_ids}
        elsif x =~ /note/
          query_h << { :privacy => "friend", :kind=>"note", :created_user_id.in=>friend_ids }
          query_h << { :privacy => "select", :created_user_id.in=>friend_ids, :publised_user_id=>Core.profile.id, :kind=>"note" }
        else
          query_h  << {:kind=>x, :content_id=>Core.profile.id, :created_user_id.in=>friend_ids}
        end
      end
      query_h << {:kind.in => project_activity, :project_id.in=>project_ids, :created_user_id.in=>friend_ids } unless project_ids.blank?
      query_h << {:privacy=>"project_activity", :kind.ne=>"activity_comment", :project_id.in=>project_ids, :created_user_id.in=>friend_ids } if !project_ids.blank? and activity_config[:project_activity]!="off"
      query_h << {:privacy=>"project_activity", :kind=>"activity_comment", :project_id.in=>project_ids, :created_user_id.in=>friend_ids } if !project_ids.blank? and activity_config[:project_activity_comment]!="off"
      cg_ids = Sns::CustomGroup.any_of({:friend_user_id => Core.profile.id},{:user_id=>Core.profile.id})
      cg_ids.each do |cg|
        query_h << {:privacy=>cg.sequence, :kind.ne=>"note", :created_user_id.in=>friend_ids}
        query_h << {:privacy=>cg.sequence, :kind=>"note", :created_user_id.in=>friend_ids} if activity_config[:note]=="on"
      end unless cg_ids.blank?
      if options[:custom_group_id]
        query_h << {:privacy=>options[:custom_group_id], :kind.ne=>"note"}
        query_h << {:privacy=>options[:custom_group_id], :kind=>"note"} if activity_config[:note]=="on"
      end
      if options[:fav]=="1"
        criteria.any_of(query_h).where("favorites.created_user_id"=>Core.profile.id)
      else
        criteria.any_of(query_h)
      end
    end

    def p_call(friend_ids,project_ids,options={})
      query_h = [
      { :privacy => "friend",:created_user_id=>Core.profile.id, :kind.ne=>"note" },
      { :privacy => "all" , :kind.ne=>"note" },
      { :privacy => "closed",:created_user_id=>Core.profile.id , :kind.ne=>"note" },
      { :privacy=>"group", :pr_group_id=>Core.user_group.id, :kind.ne=>"note" },
      { :privacy=>"group", :created_user_id=>Core.profile.id, :kind.ne=>"note" },
      { :privacy=>"select", :publised_user_id=>Core.profile.id, :kind.ne=>"note" },
      { :privacy=>"select",:created_user_id=>Core.profile.id, :kind.ne=>"note" }
      ]
      query_h << { :privacy => "public" } if options[:show_pubic]==1
      query_h << { :privacy => "friend", :created_user_id.in=>friend_ids, :kind.ne=>"note" } unless friend_ids.blank?
      activities = ["project","project_thread","project_comment", "project_member","proposal","note","schedule","project_schedule"]
      activity_config = Core.profile.activity_config
      project_activity = []
      activities.each do |x|
        next if activity_config[x.to_sym]=="off"
        if x =~ /project/
          project_activity << x unless x =~ /member/
          query_h  << {:kind=>x, :content_id=>Core.profile.id, :exclude_user_id.ne=>Core.profile.id}
          query_h  << {:kind=>x, :content_id=>Core.profile.id, :exclude_user_id.exists=>false}
        elsif x =~ /note/
          query_h << { :privacy => "friend",:created_user_id=>Core.profile.id, :kind=>"note" }
          query_h << { :privacy => "friend", :created_user_id.in=>friend_ids, :kind=>"note" } if friend_ids
          query_h << { :privacy => "all" , :kind=>"note" }
          query_h << { :privacy => "closed",:created_user_id=>Core.profile.id , :kind=>"note" }
          query_h << { :privacy=>"group", :pr_group_id=>Core.user_group.id, :kind=>"note" }
          query_h << { :privacy=>"group", :created_user_id=>Core.profile.id, :kind=>"note" }
          query_h << { :privacy=>"select", :publised_user_id=>Core.profile.id, :kind=>"note" }
          query_h << { :privacy=>"select",:created_user_id=>Core.profile.id, :kind=>"note" }
        else
          query_h  << {:kind=>x, :content_id=>Core.profile.id}
        end
      end
      unless project_ids.blank?
        query_h << {:kind.in => project_activity, :project_id.in=>project_ids, :exclude_user_id.ne=>Core.profile.id}
        query_h << {:kind.in => project_activity, :project_id.in=>project_ids, :exclude_user_id.exists=>false}
      end
      query_h << {:privacy=>"project_activity", :kind.ne=>"activity_comment", :project_id.in=>project_ids} if !project_ids.blank? and activity_config[:project_activity]!="off"
      query_h << {:privacy=>"project_activity", :kind=>"activity_comment", :project_id.in=>project_ids } if !project_ids.blank? and activity_config[:project_activity_comment]!="off"

      cg_ids = Sns::CustomGroup.any_of({:friend_user_id => Core.profile.id},{:user_id=>Core.profile.id})
      cg_ids.each do |cg|
        query_h << {:privacy=>cg.sequence, :kind.ne=>"note"}
        query_h << {:privacy=>cg.sequence, :kind=>"note"} if activity_config[:note]!="off"
      end unless cg_ids.blank?
      if options[:fav]=="1"
        criteria.any_of(query_h).where("favorites.created_user_id"=>Core.profile.id)
      else
        criteria.any_of(query_h)
      end
    end

    def call_my_news(project_ids,profile_id,user_group_id,options={})
      query_h = [
        { :privacy => "friend", :created_user_id=>profile_id, :kind.ne=>"note" },
        { :privacy => "closed",:created_user_id=>profile_id , :kind.ne=>"note" },
        { :privacy=>"group",:created_user_id=>profile_id, :kind.ne=>"note" },
        { :privacy => "all" , :kind.ne=>"note", :created_user_id=>profile_id },
        { :privacy => "public", :created_user_id=>profile_id, :kind.ne=>"note" },
        { :privacy=>"select", :created_user_id=>profile_id, :kind.ne=>"note" }
      ]
      activities = ["project_thread","project_comment", "project_member","proposal","note","schedule","project_schedule"]
      activity_config = Core.profile.activity_config
      project_activity = []
      activities.each do |x|
        next if activity_config[x.to_sym]!="on" unless options[:admin]==false
        if x =~ /project/
          project_activity << x unless x =~ /member/
        elsif x =~ /note/
          query_h << { :privacy => "friend", :created_user_id=>profile_id, :kind=>"note" }
          query_h << { :privacy => "all" , :created_user_id=>profile_id, :kind=>"note" }
          query_h << { :privacy => "closed",:created_user_id=>profile_id , :kind=>"note" }
          query_h << { :privacy=>"group",:created_user_id=>profile_id, :kind=>"note" }
          query_h << { :privacy=>"select",:created_user_id=>profile_id, :kind=>"note" }
        end
      end
      unless project_ids.blank?
        query_h << {:kind.in => project_activity, :project_id.in=>project_ids,:created_user_id=>profile_id, :exclude_user_id.exists=>false}
        query_h << {:kind.in => project_activity, :project_id.in=>project_ids,:created_user_id=>profile_id, :exclude_user_id.ne=>profile_id}
      end

      if  options[:admin]
        query_h << {:privacy=>"project_activity", :kind.ne=>"activity_comment", :project_id.in=>project_ids,:created_user_id=>profile_id} if !project_ids.blank?
        query_h << {:privacy=>"project_activity", :kind=>"activity_comment", :project_id.in=>project_ids,:created_user_id=>profile_id } if !project_ids.blank?
      else
        query_h << {:privacy=>"project_activity", :kind.ne=>"activity_comment", :project_id.in=>project_ids,:created_user_id=>profile_id} if !project_ids.blank? and activity_config[:project_activity]!="off"
        query_h << {:privacy=>"project_activity", :kind=>"activity_comment", :project_id.in=>project_ids,:created_user_id=>profile_id } if !project_ids.blank? and activity_config[:project_activity_comment]!="off"
      end
      cg_ids = Sns::CustomGroup.where(:user_id=>profile_id)
      cg_ids.each do |cg|
        query_h << {:privacy=>cg.sequence, :kind.ne=>"note"}
        query_h << {:privacy=>cg.sequence, :kind=>"note"} if activity_config[:note]=="on" unless options[:admin]==false
      end unless cg_ids.blank?
      unless options[:friend_user_id].blank?
        query_h << { :privacy => "friend", :created_user_id.in=>options[:friend_user_id],"comments.created_user_id"=>profile_id}
        friend_cg = Sns::CustomGroup.where(:user_id.in=>options[:friend_user_id], :friend_user_id=>profile_id)
        friend_cg.each do |cg|
          query_h << {:privacy=>cg.sequence, :created_user_id=>cg.user_id,"comments.created_user_id"=>profile_id}
        end unless friend_cg.blank?
      end

      query_h << { :privacy=>"group","comments.created_user_id"=>profile_id, :pr_group_id=>user_group_id }
      query_h << { :privacy => "all" , "comments.created_user_id"=>profile_id }
      query_h << { :privacy => "public", "comments.created_user_id"=>profile_id, }
      query_h << { :privacy => "select", "comments.created_user_id"=>profile_id, :publised_user_id=>Core.profile.id }
      if options[:fav]=="1"
        criteria.any_of(query_h).where("favorites.created_user_id"=>profile_id)
      else
        criteria.any_of(query_h)
      end
    end

    def stack_call(friend_ids,project_ids)
      if friend_ids
        query_h = [
          { :privacy => "public", :created_user_id.in=>friend_ids },
          { :privacy => "friend", :created_user_id.in=>friend_ids }
          ]
      else
        query_h = []
      end
      cg_ids = Sns::CustomGroup.where(:friend_user_id => Core.profile.id)
      cg_ids.each do |cg|
        query_h << {:privacy=>cg.sequence}
      end unless cg_ids.blank?
      query_h << {:kind => "project", :project_id.in=>project_ids} unless project_ids.blank?

      criteria.any_of(query_h)
    end

    def p_member
      criteria.ex(:kind=> "project_member")
    end

    def lt_sequence(seq)
      if seq.blank?
        criteria.all
      else
        criteria.where(:sequence.lt => seq)
      end
    end

    def gt_sequence(seq)
      criteria.where(:sequence.gt => seq)
    end

    def lt_date(date)
      criteria.where(:updated_at.lt => date)
    end

    def gt_date(date)
      criteria.where(:updated_at.gt => date)
    end

    def is_friend_post(friend,creator)
      friend = true if Core.user.has_auth?(:manager) && creator.id != Core.profile.id
      if friend==true
        if creator.id != Core.profile.id && Core.user.has_auth?(:manager)
          cg_ids = Sns::CustomGroup.any_of({:friend_user_id => creator.id},{:user_id=>creator.id}).map(&:sequence)
        else
          cg_ids = Sns::CustomGroup.any_of({:friend_user_id => Core.profile.id},{:user_id=>Core.profile.id}).map(&:sequence)
        end
        if cg_ids.blank?
          criteria.any_of({:privacy=>"all"},{:privacy=>"public"},{:privacy=>"friend"},{:privacy=>"group",:pr_group_id=>Core.user_group.id},{:privacy=>"select", :publised_user_id=>Core.profile.id })
        else
          query_h = [{:privacy=>"all"},{:privacy=>"public"},{:privacy=>"friend"},{:privacy=>"group",:pr_group_id=>Core.user_group.id},{:privacy=>"select", :publised_user_id=>Core.profile.id }]
          cg_ids.each do |cg|
            query_h << {:privacy=>cg}
          end
          criteria.any_of(query_h)
        end
      else
        criteria.any_of({:privacy=>"all"},{:privacy=>"public"},{:privacy=>"select", :publised_user_id=>Core.profile.id },{:privacy=>"group",:pr_group_id=>Core.user_group.id})
      end
    end

    def call_friend_news(friend,creator,project_ids,profile_id,user_group_id,options={})
      friend = true if Core.user.has_auth?(:manager) && creator.id != Core.profile.id
      query_h = []
      query_h << { :privacy => "friend", :created_user_id=>profile_id, :kind.ne=>"note" } if friend==true
      query_h << { :privacy=>"group",:created_user_id=>profile_id,:pr_group_id=>Core.user_group.id, :kind.ne=>"note" }
      query_h << { :privacy => "all" , :kind.ne=>"note", :created_user_id=>profile_id }
      query_h << { :privacy => "public", :created_user_id=>profile_id, :kind.ne=>"note" }
      query_h << { :privacy=>"select", :publised_user_id=>Core.profile.id, :created_user_id=>profile_id, :kind.ne=>"note" }
      activities = ["project_thread","project_comment", "project_member","proposal","note","schedule","project_schedule"]
      activity_config = Core.profile.activity_config
      project_activity = []
      activities.each do |x|
        next if activity_config[x.to_sym]!="on" unless options[:admin]==false
        if x =~ /project/
          project_activity << x unless x =~ /member/
        elsif x =~ /note/
          query_h << { :privacy => "friend", :created_user_id=>profile_id, :kind=>"note" } if friend==true
          query_h << { :privacy => "all" , :created_user_id=>profile_id, :kind=>"note" }
          query_h << { :privacy=>"group",:created_user_id=>profile_id,:pr_group_id=>Core.user_group.id, :kind=>"note" }
          query_h << { :privacy=>"select",:created_user_id=>profile_id, :kind=>"note" }
        end
      end
      unless project_ids.blank?
        query_h << {:kind.in => project_activity, :project_id.in=>project_ids,:created_user_id=>profile_id, :exclude_user_id.exists=>false}
        query_h << {:kind.in => project_activity, :project_id.in=>project_ids,:created_user_id=>profile_id, :exclude_user_id.ne=>profile_id}
      end

      if  options[:admin]
        query_h << {:privacy=>"project_activity", :kind.ne=>"activity_comment", :project_id.in=>project_ids,:created_user_id=>profile_id} if !project_ids.blank?
        query_h << {:privacy=>"project_activity", :kind=>"activity_comment", :project_id.in=>project_ids,:created_user_id=>profile_id } if !project_ids.blank?
      else
        query_h << {:privacy=>"project_activity", :kind.ne=>"activity_comment", :project_id.in=>project_ids,:created_user_id=>profile_id} if !project_ids.blank? and activity_config[:project_activity]!="off"
        query_h << {:privacy=>"project_activity", :kind=>"activity_comment", :project_id.in=>project_ids,:created_user_id=>profile_id } if !project_ids.blank? and activity_config[:project_activity_comment]!="off"
      end
      cg_ids = Sns::CustomGroup.where(:user_id=>profile_id, :friend_user_id=>Core.profile.id)
      cg_ids.each do |cg|
        query_h << {:privacy=>cg.sequence, :kind.ne=>"note"}
        query_h << {:privacy=>cg.sequence, :kind=>"note"} if activity_config[:note]=="on" unless options[:admin]==false
      end unless cg_ids.blank?
      unless options[:friend_user_id].blank?
        query_h << { :privacy => "friend", :created_user_id.in=>options[:friend_user_id],"comments.created_user_id"=>profile_id}
        friend_cg = Sns::CustomGroup.where(:user_id.in=>options[:friend_user_id], :friend_user_id=>Core.profile.id)
        friend_cg.each do |cg|
          query_h << {:privacy=>cg.sequence, :created_user_id=>cg.user_id,"comments.created_user_id"=>profile_id}
        end unless friend_cg.blank?
      end
      query_h << { :privacy=>"group","comments.created_user_id"=>profile_id, :pr_group_id=>user_group_id }
      query_h << { :privacy => "all" , "comments.created_user_id"=>profile_id }
      query_h << { :privacy => "public", "comments.created_user_id"=>profile_id, }
      query_h << { :privacy => "select", "comments.created_user_id"=>profile_id, :publised_user_id=>Core.profile.id }
      if options[:fav]=="1"
        criteria.any_of(query_h).where("favorites.created_user_id"=>Core.profile.id)
      else
        criteria.any_of(query_h)
      end
    end


    def call_star(profile=Core.profile)
      criteria.where("favorites.created_user_id"=>profile.id)
    end

    def project_report(id,fav="0")
      query_h = [
         {:kind.in => ["project_thread","project_comment"], :project_id=>id},
         {:project_id=>id, :privacy=>"project_activity", :kind.ne=>"activity_comment"}
       ]
      if fav=="0"
        criteria.any_of(query_h)
      else
        criteria.any_of(query_h).where("favorites.created_user_id"=>Core.profile.id)
      end
    end

    def project_id_call(ids=[])
      criteria.any_in("project_id"=>ids)
    end

    def user_notice
      criteria.where(:privacy => "notice", :content_id=>Core.profile.id)
    end

    def post_update_limit
      return 15 if Core.blank?
      return Core.profile.post_update_limit
    end

    def display_limit(p_limit=post_update_limit)
      criteria.limit(p_limit)
    end


    def word_query(word,friend_ids,project_ids,options={})
      return criteria.all if word.blank?
      search_words = word.to_s.split(/[ 　]+/)
      target = []
      search_words.each do |m|
        str = m.gsub(/\./,'\.')
        target << /.*#{str}.*/
      end
      query_h = [
      { :privacy => "friend",:created_user_id=>Core.profile.id, :kind.ne=>"note", :text.all=>target },
      { :privacy => "all" , :kind.ne=>"note", :text.all=>target },
      { :privacy => "closed",:created_user_id=>Core.profile.id , :kind.ne=>"note", :text.all=>target },
      { :privacy=>"group", :pr_group_id=>Core.user_group.id, :kind.ne=>"note", :text.all=>target },
      { :privacy=>"group", :created_user_id=>Core.profile.id, :kind.ne=>"note", :text.all=>target },
      { :privacy=>"select", :publised_user_id=>Core.profile.id, :kind.ne=>"note", :text.all=>target },
      { :privacy=>"select",:created_user_id=>Core.profile.id, :kind.ne=>"note", :text.all=>target },
      ]
      if options[:show_pubic]==1
        query_h << { :privacy => "public", :kind.ne=>"note", :text.all=>target }
      end
      unless friend_ids.blank?
        query_h << { :privacy => "friend", :created_user_id.in=>friend_ids, :kind.ne=>"note", :text.all=>target }
      end

      cg_ids = Sns::CustomGroup.any_of({:friend_user_id => Core.profile.id},{:user_id=>Core.profile.id})
      cg_ids.each do |cg|
        query_h << {:privacy=>cg.sequence, :kind.ne=>"note", :text.all=>target}
      end unless cg_ids.blank?

      if options[:show_pubic]==1
        query_h << { :privacy => "public", :kind.ne=>"note", "comments.body.all"=>target }
      end
      unless friend_ids.blank?
        query_h << { :privacy => "friend", :created_user_id.in=>friend_ids, :kind.ne=>"note", "comments.body.all"=>target }
      end
      query_h << { :privacy => "friend",:created_user_id=>Core.profile.id, :kind.ne=>"note", "comments.body.all"=>target }
      query_h << { :privacy => "all" , :kind.ne=>"note", "comments.body.all"=>target }
      query_h << { :privacy => "closed",:created_user_id=>Core.profile.id , :kind.ne=>"note", "comments.body.all"=>target}
      query_h << { :privacy=>"group", :pr_group_id=>Core.user_group.id, :kind.ne=>"note", "comments.body.all"=>target }
      query_h << { :privacy=>"group", :created_user_id=>Core.profile.id, :kind.ne=>"note", "comments.body.all"=>target }
      query_h << { :privacy=>"select", :publised_user_id=>Core.profile.id, :kind.ne=>"note", "comments.body.all"=>target }
      query_h << { :privacy=>"select",:created_user_id=>Core.profile.id, :kind.ne=>"note", "comments.body.all"=>target }
      cg_ids.each do |cg|
        query_h << {:privacy=>cg.sequence, :kind.ne=>"note", "comments.body.all"=>target}
      end unless cg_ids.blank?

      criteria.any_of(query_h)
    end

    def word_query_activity(word,project_ids)
      search_words = word.to_s.split(/[ 　]+/)
      target = []
      search_words.each do |m|
        str = m.gsub(/\./,'\.')
        target << /.*#{str}.*/
      end
      query_h = []
      if !project_ids.blank?
        query_h << {:privacy=>"project_activity", :kind.ne=>"activity_comment", :project_id.in=>project_ids , :text.all=>target}
        query_h << {:privacy=>"project_activity", :kind.ne=>"activity_comment", :project_id.in=>project_ids , "comments.body.all"=>target }
      end
      criteria.any_of(query_h)
    end

  end



end

