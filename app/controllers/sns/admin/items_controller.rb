# encoding: utf-8
class Sns::Admin::ItemsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout
  def pre_dispatch
    @cat = case params[:cat]
    when "note"
      "note"
    when "file"
      "file"
    when "photo"
      "photo"
    when "video"
      "video"
    when "news"
      "news"
    when "enquete"
      "enquete"
    when "favorite"
      "favorite"
    else
      "news"
    end
    @class = @cat
    @title = case @cat
    when "note"
      "ノート"
    when "file"
      "ファイル"
    when "photo"
      "フォト"
    when "video"
      "動画"
    when "news"
      "マイニュース"
    when "enquete"
      "投票"
    when "favorite"
      "スター"
    else
      "ノート"
    end
    @use_friend_list = true
    @fav = params[:fav] || "0"
  end

  def index
    prof_friend = Core.profile.get_friend_info
    @friends = prof_friend[0]
    @state_str=""
    p_ids = Core.profile.project_select
    if @cat=="news"
      @feeds = Sns::Post.call_my_news(p_ids,Core.profile.id , Core.user_group.id,{:friend_user_id=>prof_friend[1],:fav=>@fav}).display_limit.desc(:sequence)
    else
      @feeds = Sns::Post.k_call(@cat).p_call(prof_friend[1],p_ids,{:fav=>@fav}).display_limit.desc(:sequence)
    end
    @date_str = @feeds.last.sequence unless @feeds.blank?
  end

  def destroy
    item = Sns::Post.find(params[:id])
    if item
      item.destroy
      case item.kind
      when "video"
        video_item = Sns::Video.find(:first, :conditions=>{:_id=>item.content_id[0]})
        video_item.destroy  if video_item
      when "photo"
        files_item = Sns::Photo.any_in("_id"=>item.content_id)
        files_item.each do |f|
          f.destroy
        end
      when "file"
        files_item = Sns::File.any_in("_id"=>item.content_id)
        files_item.each do |f|
          f.destroy
        end
      end
    end
    return redirect_to "/_admin"
  end

protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end

end