# encoding: utf-8
class Sns::Admin::MessageBoardsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def index
    @group = Core.user_group
    @users = Sns::Profile.get_user_select(@group.id,nil,{:profile_select=>1}).to_a

    group_users = []
    @users.each do |user|
      uid = user.account
      group_users << user if uid.slice(0,6) == @group.code.to_s
    end
    group_users.each{|gu| @users.delete_if{|u| u.account == gu.account}}
    @users = group_users + @users
  end

  def edit
    @item = Sns::Profile.find(params[:id])
  end

  def update
    @item = Sns::Profile.find(params[:id])
    @item.message = params[:item][:message]
    @item.save
    return redirect_to sns_message_boards
  end

  def update_message
    @item = Sns::Profile.find(params[:id])
    @item.message = params[:prof_message][:message]
    @item.save
    respond_to do |format|
      format.js { render :layout => false }
    end
  end

protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end
end
