# -*- encoding: utf-8 -*-
class Sns::Admin::Managers::DisplayItemsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    return redirect_to "/_admin" unless Core.user.has_auth?(:manager)
    @current = "items"
  end

  def index
    setting = {
    :post => "enabled",
    :file=>"enabled",
    :base_info=>"enabled",
    :history=>"enabled",
    :address=>"friend",
    :skill=>"enabled",
    :interest=>"enabled",
    :pr=>"enabled"
    }
    @item = Sns::Management.first || Sns::Management.create(setting)
  end

  def update
    @item = Sns::Management.first
    @item.attributes = params[:item]
    @item.save
    return redirect_to sns_display_items_path
  end

protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end
end
