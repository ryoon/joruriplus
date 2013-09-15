# encoding: utf-8
class Sns::Admin::PrivaciesController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @edit_current = "privacy"
  end

  def index
    @item = Core.profile.privacy
    return redirect_to new_sns_privacy_path if @item.blank?
  end

  def new
    @item = Core.profile.privacy
    return redirect_to edit_sns_privacy_path(@item) unless @item.blank?
    default_setting = Core.profile.privacy_config
    @item = Sns::Privacy.new(default_setting)
  end

  def create
    Core.profile.privacy = Sns::Privacy.new(params[:item])
    return redirect_to sns_privacies_path
  end

  def edit
    @item = Core.profile.privacy
  end

  def update
    @item = Core.profile.privacy
    @item.update_attributes(params[:item])
    if @item.save
      flash[:notice] = "プロフィールを編集しました。"
      return redirect_to sns_privacies_path
    else
      render :action=>:edit
    end
  end


protected

  def select_layout
    layout = "admin/sns/config"
    layout
  end

end
