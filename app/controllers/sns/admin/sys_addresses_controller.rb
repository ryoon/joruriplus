# encoding: utf-8
class Sns::Admin::SysAddressesController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @search_current = params[:target] || "word"
    if params[:g_id].blank?
      @group_id = params[:p_id] || 0
    else
      @group_id = params[:g_id]
    end
    @my_friend = Sns::Friend.find(:first, :conditions=>{:user_id => Core.profile.id})
    @show_id = ""
  end

  def index
    @root = Sys::Group.find_by_id(1)
    return http_error(404) unless @root
    @parents = []
    @group   = @root
    @groups  = @group.code_enabled_children


    @users = []
    unless params[:word].blank?
      target = params[:word]
      @users = Sns::Profile.word_query(target).order_by([[:sort_no, :asc]])
      @show_id = "Search1"
    end

    respond_to do |format|
      format.html {}
      format.xml {}
      format.js   {}
    end
  end

  def show
    @item = Sns::Profile.where(:_id=>params[:id]).first
    return http_error(404) if @item.blank?
    @my_friends = Sns::Friend.find(:first, :conditions=>{:user_id=>Core.profile.id})
    @items = Core.profile.get_common_friends(@item,@my_friends)
    respond_to do |format|
      format.html { render :layout=>false }
    end
  end

  def child_groups
    @group = Sys::Group.find_by_id(params[:id])
    return http_error(404) unless @group

    @groups  = @group.enabled_children

    respond_to do |format|
      format.xml
    end
  end

  def child_users
    @group = Sys::Group.find_by_id(params[:id])
    return http_error(404) unless @group
    @users = Sns::Profile.get_user_select(params[:id],nil,{:profile_select=>1})
    respond_to do |format|
      format.xml  { }
    end
  end

  def child_items
    @group = Sys::Group.find_by_id(params[:id])
    return http_error(404) unless @group
    @groups = @group.enabled_children
    @users = Sns::Profile.get_user_select(params[:id],nil,{:profile_select=>1})
    respond_to do |format|
      format.xml  { }
    end
  end

protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end
end
