require "date"
# -*- encoding: utf-8 -*-
class Sns::Admin::Managers::PhotoCountsController< Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  include Sns::Controller::Util
  layout :select_layout

  def pre_dispatch
    return redirect_to "/_admin" unless Core.user.has_auth?(:manager)
    @current = "count"
    @kind = params[:kind] || "p_photo"
  end

  def index
    @count = Sns::Profile.where(:photo_path.ne=>"").count if @kind == "p_photo"
    @count = Sns::Profile.where(:message.ne=>"").to_a.delete_if{|x| x.message.blank?}.count if @kind == "p_msg"
    @count = Sns::Friend.where(:friend_user_id.ne=>[]).count if @kind == "friend"
    @count = Sns::CustomGroup.find(:all).map{|x| x.user_id}.uniq.count if @kind == "c_group"
    respond_to do |format|
      format.html { render :layout=>false }
    end
  end

protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end
end

