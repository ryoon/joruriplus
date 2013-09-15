# encoding: utf-8
class Sns::Admin::NoticesController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @edit_current = "mail_notice"
  end

  def index
    @item = Core.profile.notice
    return redirect_to new_sns_notice_path if @item.blank?
  end

  def new
    @item = Core.profile.notice
    return redirect_to edit_sns_notice_path(@item) unless @item.blank?
    default_setting = Core.profile.notice_config
    @item = Sns::MailNotice.new(default_setting)
  end

  def create
    Core.profile.notice = Sns::MailNotice.new(params[:item])
  end

  def edit
    @item = Core.profile.notice
  end

  def update
    @item = Core.profile.notice
    @item.update_attributes(params[:item])
    if @item.save
      flash[:notice] = "プロフィールを編集しました。"
      return redirect_to sns_notices_path
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
