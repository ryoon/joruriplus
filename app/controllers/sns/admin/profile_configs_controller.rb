# encoding: utf-8
class Sns::Admin::ProfileConfigsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  include Sns::Controller::Setting
  layout :select_layout

  def pre_dispatch
    @edit_current  = params[:cl] || "base"
  end

  def index
    return redirect_to sns_profile_photos_path unless is_enabled(@edit_current,Core.user.has_auth?(:manager))
    @item = Core.profile
    @office = @item.office
  end

  def new
    @item = Core.profile
    @office = @item.office
  end

  def create
    return redirect_to :action => 'index'
  end

  def edit
    @item = Core.profile
  end

  def update
    @item = Core.profile
    @item.update_attributes(params[:item])
    if @item.save
      flash[:notice] = "プロフィールを編集しました。"
      return redirect_to %Q(#{sns_profile_configs_path}?cl=#{@edit_current})
    else
      render :action=>:edit
      return
    end
  end

  def show
    @item = Core.profile
  end

  def destroy
    #
  end

  def message
    @item = Core.profile
    @item.message = params[:prof_message][:message]
    @item.save
    respond_to do |format|
      format.js { render :layout => false }
    end
  end


protected

  def select_layout
    layout = "admin/sns/config"
    layout
  end

end
