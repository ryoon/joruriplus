# encoding: utf-8
class Sns::Admin::ProfilesController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @current = params[:cl] || "feed"
    @class = "newsfeed"
    @profile = Sns::Profile.find( :first, :conditions => {:user_id => Core.user.id} )
    if @profile.blank?
     @profile = Sns::Profile.create(:user_id=>Core.user.id , :name=>Core.user.name, :account=>Core.user.account)
   end
   @subfeed = params[:subfeed] || "newsfeed"
   @use_friend_list = true
   @fav = params[:fav] || "0"
  end

  def index
    @pr_id = "member"
    if @subfeed=="public" || @subfeed=="all" || @subfeed=="group"
      @pr_id = @subfeed
      @feeds = Sns::Post.public_stream(@subfeed,{:fav=>@fav}).display_limit.desc(:sequence)
    elsif @subfeed == "member"
      @pr_id = "friend"
      prof_friend = @profile.get_friend_info
      @feeds = Sns::Post.custom_call(prof_friend[1], nil,{:fav=>@fav}).display_limit.desc(:sequence)
    elsif @subfeed =~ /^cg_(\d+)$/
      @pr_id = "#{$1}"
      custom_friends = []
      c_group = Sns::CustomGroup.where(:sequence=>@pr_id.to_i, :user_id=>Core.profile.id).first
      custom_friends = c_group.friend_user_id unless c_group.blank?
      if custom_friends.blank?
        @feeds = nil
      else
        @feeds = Sns::Post.custom_call(custom_friends, nil,{:custom_group_id=>@pr_id.to_i,:fav=>@fav}).display_limit.desc(:sequence)
      end
    else
      prof_friend = @profile.get_friend_info
      p_ids = Core.profile.project_select
      @feeds = Sns::Post.p_call(prof_friend[1], p_ids,{:fav=>@fav}).display_limit.desc(:sequence)
    end
  end

  def show
    class_params(params[:cl])
    @item  = Sns::Profile.find(:first, :conditions => {:account => params[:id]} )
    @office = @item.office
    return redirect_to sns_profiles_path if @item.blank?
    @friends = @item.show_friends
    prof_friend = @item.get_friend_info

    @is_friend = @item.is_friend?(Core.profile)
    if @cat=="newsfeed"
      if Core.user.has_auth?(:manager) && @item.id != Core.profile.id
        profile_group = @item.user_group
        p_ids = @item.project_select
        @feeds = Sns::Post.call_my_news(p_ids, @item.id , profile_group.id,{:friend_user_id=>prof_friend[1]}).display_limit.desc(:sequence)
      else
        my_friend = Core.profile.get_friend_info
        my_group = Core.profile.user_group
        my_p_ids = Core.profile.project_select
        @feeds = Sns::Post.call_friend_news(@is_friend,@item ,my_p_ids, @item.id , my_group.id,{:friend_user_id=>my_friend[1]}).display_limit.desc(:sequence)
      end
    else
      @feeds = Sns::Post.post_user(@item.id).is_friend_post(@is_friend,@item).k_call(@cat).display_limit.desc(:sequence)
    end
    @date_str = @feeds.last.sequence unless @feeds.blank?
  end

  def class_params(cl)
    @cat = case params[:cl]
    when "note"
      "note"
    when "file"
      "file"
    when "photo"
      "photo"
    when "video"
      "video"
    when "data"
      "data"
    else
      "newsfeed"
    end
    @class = @cat
    @class = "newsFeed" if @cat=="newsfeed"
    @title = case @cat
    when "note"
      "ノート"
    when "file"
      "ファイル"
    when "photo"
      "フォト"
    when "video"
      "動画"
    else
      "ニュースフィード"
    end
  end

protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end

end
