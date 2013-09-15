# encoding: utf-8
class Sns::Admin::CustomGroupsController  < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout


  def pre_dispatch
    @edit_current = "group"
    @gid  = params[:gid] || "0"
    @friends = Core.profile.show_friends
  end

  def index
    @items = Sns::CustomGroup.find(:all, :conditions=>{:user_id=>Core.profile.id})
  end

  def show
    @item = Sns::CustomGroup.find(:first, :conditions=>{:_id=>params[:id]})
    return redirect_to sns_custom_groups_path if @item.blank?
    if @item.friend_user_id.blank?
      @users = []
    else
      @users = Sns::Profile.any_in(:_id=>@item.friend_user_id)
    end
  end

  def new
    @item = Sns::CustomGroup.new
    @item.user_id = Core.profile.id
    @users = Core.profile.friends_select
    @members = []
  end


  def create
    @users = Core.profile.friends_select
    @members = []
    if params[:item][:friend_user_id]
      params[:item][:friend_user_id] = params[:item][:friend_user_id].uniq
      @members = Sns::Profile.any_in("_id" => params[:item][:friend_user_id])
      member_set = []
      @members.each do |m|
        member_set << m.id
      end
      params[:item][:friend_user_id] = member_set
    end
    @item = Sns::CustomGroup.new(params[:item])
    if @item.save
      flash[:notice] = "カスタムグループを編集しました。"
      return redirect_to sns_custom_groups_path
    else
      render :action=>:new
    end
  end

  def edit
    @item = Sns::CustomGroup.find(:first, :conditions=>{:_id=>params[:id]})
    return redirect_to sns_custom_groups_path if @item.blank?
    @users = Core.profile.friends_select
    if @item.friend_user_id.blank?
      @members = []
    else
      @members = Sns::Profile.any_in("_id" =>@item.friend_user_id)
    end
  end

  def update
    @item = Sns::CustomGroup.find(:first, :conditions=>{:_id=>params[:id]})
    return redirect_to sns_custom_groups_path if @item.blank?
    @users = Core.profile.friends_select
    @members = []
    if params[:item][:friend_user_id].blank?
      member_set = []
    else
      params[:item][:friend_user_id] = params[:item][:friend_user_id].uniq
      @members = Sns::Profile.any_in("_id" => params[:item][:friend_user_id])
      member_set = []
      @members.each do |m|
        member_set << m.id
      end
      params[:item][:friend_user_id] = member_set
    end
    @item.attributes = params[:item]
    if @item.save
      flash[:notice] =  "カスタムグループを編集しました。"
      return redirect_to sns_custom_groups_path
    else
      render :action=>:edit
    end
  end

  def destroy
    @item = Sns::CustomGroup.find(:first, :conditions=>{:_id=>params[:id]})
    @item.destroy
    return redirect_to sns_custom_groups_path
  end


  def user_field
    html_select = ""
    ids = params[:u_id]
    if params[:kind]=="del"
      ids.delete(params[:del_id])
    end
    unless ids.blank?
      selects = Sns::Profile.any_in(:_id=>ids)
      unless selects.blank?
        selects = selects.collect{|x| [x.name, x.id]}
        selects.each do |value , key|
          html_select << %Q(#{value}<input id='item_friend_user_id_' name='item[friend_user_id][]' type='hidden' value='#{key}' />)
          html_select << %Q(<button type="button" onclick="del_user('#{key}')">削除</button><br />)
        end
      end
    end
    respond_to do |format|
      format.csv { render :text => html_select ,:layout=>false ,:locals=>{:f=>@item} }
    end
  end


protected

  def select_layout
    layout = "admin/sns/config"
    layout
  end


end
