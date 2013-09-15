# -*- encoding: utf-8 -*-
class Sns::Admin::Projects::ProposalsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @project = Sns::Project.find(:first, :conditions=>{:code=>params[:parent]})
    return redirect_to sns_projects_path if @project.blank?
    return redirect_to sns_projects_path if @project.auth_check==false
    @project_code = @project.code
    @u_role = @project.is_admin?
    @class = "join"
    @kind =  params[:kind] || "join"
   if @kind=="join"
      @title = "参加希望"
    else
      @title = "退会"
    end
  end

  def motion
    if @kind=="join"
      if params[:do]=="cansel"
        Sns::FriendProposal.destroy_all(:conditions=>{:fr_user_id=>Core.profile.id, :project_id=>@project.id, :kind=>"project_join"})
        return redirect_to sns_project_path(@project.code)
      else
        @item = Sns::FriendProposal.new
        @item.kind="project_join"
      end
    else
      my_membership = @project.members.where({:user_id=>Core.profile.id}).first
      return redirect_to sns_members_path(@project.code)  if my_membership.blank?
      if params[:do]=="cansel"
        member_state = "enabled"
        Sns::FriendProposal.destroy_all(:conditions=>{:fr_user_id=>Core.profile.id, :project_id=>@project.id, :kind=>"project_leave"})
        my_membership.state=member_state
        my_membership.save
        return redirect_to sns_members_path(@project.code)
      else
        @item = Sns::FriendProposal.new
        @item.kind="project_leave"
      end
    end
  end

  def create
    if @kind=="leave"
      my_membership = @project.members.where({:user_id=>Core.profile.id}).first
      return redirect_to sns_members_path(@project.code)  if my_membership.blank?
      my_membership.state="pre-disabled"
      my_membership.save
      path = sns_members_path(@project.code)
    else
      path = sns_project_path(@project.code)
    end
    managers = @project.managers
    managers.each do |manager|
        proposal_params = {
            :fr_user_id => Core.profile.id,
            :to_user_id => manager.user_id,
            :body => params[:item][:body],
            :state => "unread",
            :project_id => @project.id,
            :kind=>params[:item][:kind]
       }
       item = Sns::FriendProposal.create(proposal_params)
    end
    return redirect_to path
  end


protected
  def select_layout
    layout = "admin/sns/project"
    layout
  end
end

