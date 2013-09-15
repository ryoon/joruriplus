# encoding: utf-8
class Sns::Admin::OfficesController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  include Sns::Controller::Setting
  layout :select_layout

  def pre_dispatch
    @edit_current = "office"
    return redirect_to sns_profile_photos_path unless is_enabled(@edit_current,Core.user.has_auth?(:manager))
  end

  def index
    @item = Core.profile.office
    @office = @item
    return redirect_to new_sns_office_path if @item.blank?
  end

  def new
    @item = Sns::Office.new
  end

  def create
    Core.profile.office = Sns::Office.new(params[:item])
    return redirect_to sns_offices_path
  end


  def edit
    @item = Core.profile.office
  end

  def update
    @item = Core.profile.office
    @item.update_attributes(params[:item])
    if @item.save
      flash[:notice] = "プロフィールを編集しました。"
      return redirect_to sns_offices_path
    else
      render :action=>:edit
    end
  end


  def destroy
    @item = Core.profile.office
    @item.destroy
    return redirect_to new_sns_office_path
  end


protected

  def select_layout
    layout = "admin/sns/config"
    layout
  end

end
