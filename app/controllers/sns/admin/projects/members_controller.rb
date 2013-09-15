# -*- encoding: utf-8 -*-
class Sns::Admin::Projects::MembersController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @project = Sns::Project.find(:first, :conditions=>{:code=>params[:parent]})
    return redirect_to sns_projects_path if @project.blank?
    if params[:action]=="approval"
      #権限判定をスキップ
    else
      return redirect_to sns_projects_path if @project.auth_check==false
    end

    @project_code = @project.code
    @u_role = @project.is_admin?
    @class = "join"
    @kind =  params[:kind] || "member"
    if @kind=="member"
      @title = "メンバー"
    else
      @title = "管理者"
    end
  end

  def index
    @pending = @project.pending_members(true, true)
    manager_ids = []
    manager_ids += @project.managers.map{|user| user.user_id}
    managers = @project.managers
    @managers = managers.sort{|a,b| a.user.sort_no.to_s <=> b.user.sort_no.to_s}
    if manager_ids.blank?
      members = @project.members
    else
      members = @project.members.where(:user_id.nin=>manager_ids)
    end
    @members = members.sort{|a,b| a.user.sort_no.to_s <=> b.user.sort_no.to_s}
    @my_membership = @project.members.where({:user_id=>Core.profile.id}).first
    @already_submit = false
    @already_submit = true if @my_membership.state=="pre-disabled" if @my_membership
  end

  def new
    @item = Sns::FriendProposal.new
    @users = Sns::Profile.get_user_select(Core.user_group.id,nil,{:select=>true})
    @members = []
    @managers = []
  end

  def create
    @item = Sns::FriendProposal.new
    @users = Sns::Profile.get_user_select(Core.user_group.id,nil,{:select=>true})
    if params[:user_id]
      params[:user_id] = params[:user_id].uniq
      @members = Sns::Profile.any_in("_id" =>params[:user_id])
    end
    if params[:manager_id]
      params[:manager_id] = params[:manager_id].uniq
      @managers = Sns::Profile.any_in("_id" =>params[:manager_id])
    end
    if @item.save_with_rels(params,:create,{:members=>@members, :managers=>@managers})
      flash[:notice]="選択したユーザーに招待通知を送信しました。"
      return redirect_to sns_members_path(@project.code)
    else
      flash[:notice]="ユーザーが選択されていません。"
      render :action=>:new
    end
  end

  def edit
    @item = @project.members.find(:first, :conditions=>{:_id=>params[:id]})
    p_members = @project.members
    @members = []
    p_members.each do |p|
      user = Sns::Profile.find(:first, :conditions=>{:_id=>p.user_id})
      @members << user unless user.blank?
    end if p_members
    @users = Sns::Profile.get_user_select(Core.user_group.id,nil,{:select=>true})
  end

  def update
    @users = Sns::Profile.get_user_select(Core.user_group.id,nil,{:select=>true})
    @item = @project.members.find(:first, :conditions=>{:_id=>params[:id]})
    if params[:user_id]
      params[:user_id] = params[:user_id].uniq
      @members = Sns::Profile.any_in("_id" =>params[:user_id])
    end
    if @project.save_with_rels params, :edit
      flash[:notice] = "メンバーを編集しました。"
      feed_post(nil,:edit)
      return redirect_to sns_project_path(@project.code)
    else
      render :action=>:edit
      return
    end
  end

  def destroy
    @item = @project.members.find(:first, :conditions=>{:user_id=>params[:id]})
    @item.destroy if @item
    @m_item = @project.managers.find(:first, :conditions=>{:user_id=>params[:id]})
    @m_item.destroy if @m_item

    flash[:notice] = "指定したメンバーを削除しました。"
    return redirect_to sns_members_path(@project.code,{:kind=>@kind})
  end

  def proposal
    @item = Sns::FriendProposal.new
    @users = Sns::Profile.get_user_select(Core.user_group.id,nil,{:select=>true})
    if @kind=="manager" && @project.is_admin?
      @warning = "自動的にメンバー権限も付与されます。"
      @members = @project.pending_members(false, true)
    else
      @members = @project.pending_members(true, true)
    end
  end
  def invite
    @item = Sns::FriendProposal.new
    @users = Sns::Profile.get_user_select(Core.user_group.id,nil,{:select=>true})
    if params[:user_id]
      params[:user_id] = params[:user_id].uniq
      @members = Sns::Profile.any_in("_id" =>params[:user_id])
    end
    options={}
    if @kind=="manager" && @project.is_admin?
      @warning = "自動的にメンバー権限も付与されます。"
      invite_mode  = :manager
      options[:managers]=@members
    else
      invite_mode  = :proposal
      options[:members]=@members
    end
    if @item.save_with_rels(params,invite_mode,options)
      flash[:notice]="選択したユーザーに招待通知を送信しました。"
      return redirect_to sns_members_path(@project.code,{:kind=>@kind})
    else
      render :action=>:proposal
    end
  end

  def approval
    item = Sns::FriendProposal.find(params[:id])
    to_index = "invite"
    if params[:do]=="recognize"
      item.state="recognized"
      if item.kind == "project" || item.kind == "project_manager"
        item.recognize_notice
        feed_post(item,:participate)
      end
    else
      item.state="refused"
    end
    if item.kind == "project_leave"
      item.leave_project(item.state)
      membership = @project.members.where({:user_id=>item.fr_user_id, :state=>"pre-disabled"}).first
      membership.state="enabled"
      membership.save
      to_index = "leave"
    elsif item.kind =="project_join"
      item.join_project(item.state)
      to_index = "join"
    end
    item.save
    return redirect_to sns_friend_proposals_path({:kind=>to_index})
  end

  def group_field
    html_select = "<option value=''></option>"
    if params[:p_id].blank? || params[:p_id].to_i == 0
      groups = nil
    else
      groups = Sys::Group.find(:all , :conditions=>["parent_id =? AND state = ? AND level_no = ?",params[:p_id],"enabled",3],:order=>:sort_no)
    end
    unless groups.blank?
      groups = groups.collect{|x| ["(#{x.code})#{x.name}", x.id]}
      groups.each do |value , key|
        html_select << "<option value='#{key}'>#{value}</option>"
      end
    end
    respond_to do |format|
      format.csv { render :text => html_select ,:layout=>false ,:locals=>{:f=>@item} }
    end
  end

  def users_field
    html_select = ""
    if params[:p_id]=="0"
      html_select = friends_list
    else
      html_select = user_list(params[:p_id], params[:g_id])
    end
    respond_to do |format|
      format.csv { render :text => html_select ,:layout=>false ,:locals=>{:f=>@item} }
    end
  end

  def user_list(p_id, g_id)
    ret = ""
    if g_id.blank?
      group_id = p_id
    else
      group_id = g_id
    end
    users = Sns::Profile.get_user_select(group_id,nil,{:select=>true})
    if users
      users.each do |value , key|
        ret << "<option value='#{key}'>#{value}</option>"
      end
    end
    return ret
  end

  def friends_list
    ret = ""
    friends = Core.profile.get_friend_info[0]
    if friends
      friends.each do |f|
        ret << "<option value='#{f.id}'>#{f.name}</option>"
      end
    end
    return ret
  end

protected

  def feed_post(item,mode)
    if mode==:edit
      message = %Q(#{@project.title}の<a href="#{sns_members_path(@project.code)}" target="_blank">メンバー</a>を更新しました。)
      item_id = nil
    elsif mode == :participate
      message =  %Q(メンバー更新：#{Core.profile.name}さんが<a href="#{sns_project_path(@project_code)}" >#{@project.title}</a>に参加しました。)
      item_id = item.id
    else
      return
    end
    attribute = {
            :text =>message,
            :kind =>["project"],
            :privacy =>"project",
            :content_id=>[item_id],
            :created_user_id=>Core.profile.id,
            :project_id=>@project.id,
            :is_project=>1
          }
    Sns::Post.create(attribute)
  end


  def select_layout
    layout = "admin/sns/project"
    layout
  end
end
