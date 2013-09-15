# encoding: utf-8
class Sns::Admin::ActivityConfigsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @edit_current = "activity"
  end

  def index
    @item = Core.profile.a_config
    return redirect_to new_sns_activity_config_path if @item.blank?
  end

  def new
    @item = Core.profile.a_config
    return redirect_to edit_sns_activity_config_path(@item) unless @item.blank?
    default_setting = Core.profile.activity_config
    @item = Sns::ActivityConfig.new(default_setting)
  end

  def create
    Core.profile.a_config = Sns::ActivityConfig.new(params[:item])
    return redirect_to sns_activity_configs_path
  end

  def edit
    @item = Core.profile.a_config
  end

  def update
    @item = Core.profile.a_config
    @item.update_attributes(params[:item])
    if @item.save
      flash[:notice] = "プロフィールを編集しました。"
      return redirect_to sns_activity_configs_path
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
