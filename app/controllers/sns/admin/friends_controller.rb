# encoding: utf-8
class Sns::Admin::FriendsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @current = params[:cl] || "to"
    @cg_id = params[:cg_id] || nil
    @class = "companion"
    @my_friend = Sns::Friend.find(:first, :conditions=>{:user_id => Core.profile.id})
  end

  def index
    show_member_num = 50
    @custom_groups = Sns::CustomGroup.find(:all, :conditions=>{:user_id=>Core.profile.id})
    if @my_friend.blank?
      @items = nil
    else
      if @cg_id.blank?
        friends_ids = @my_friend.friend_user_id
        @items = Sns::Profile.any_in(:_id=>friends_ids).paginate(:page => params[:page], :per_page => show_member_num)
      else
        c_group = Sns::CustomGroup.where(:sequence=>@cg_id).first
        if c_group.blank?
          @items = nil
        else
          @items = Sns::Profile.any_in(:_id=>c_group.friend_user_id).paginate(:page => params[:page], :per_page => show_member_num)
        end
      end
    end
  end

  def destroy
    remove_user = Sns::Friend.remove(params[:to_user])
    if remove_user
      flash[:notice]="選択したユーザーを友達から外しました。"
    else
      flash[:notice]="選択したユーザーを友達から外す処理に失敗しました。"
    end
    return redirect_to sns_friends_path
  end

protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end

end
