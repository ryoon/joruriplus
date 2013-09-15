# -*- encoding: utf-8 -*-
class Sns::Admin::Managers::InformationsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    return redirect_to "/_admin" unless Core.user.has_auth?(:manager)
    if params[:g_id].blank?
      @group_id = params[:p_id] || 0
    else
      @group_id = params[:g_id]
    end
    @limit = params[:limit] || 30
    @current = "list"
  end

  def index
    if @group_id.blank? || @group_id == 0
      @items = Sns::Profile.all.asc(:account).paginate(:page => params[:page], :per_page => @limit.to_i)
    else
      selects = Sns::Profile.get_user_select(@group_id,nil,{:user_select=>1})
      if selects.blank?
        @items = nil
      else
        @items = Sns::Profile.any_in("user_id" =>  selects).asc(:account).paginate(:page => params[:page], :per_page => @limit.to_i)
      end
    end
  end

  def group_field
    html_select = "<option value=''></option>"
    if params[:p_id].blank? || params[:p_id].to_i == 0
      groups = nil
    else
      groups = Sys::Group.find(:all , :conditions=>["parent_id =? AND state = ? AND level_no = ?",params[:p_id],"enabled",3],:order=>:sort_no)
    end
    unless groups.blank?
      groups = groups.collect{|x| ["(#{x.code})#{x.name}", x.id]}
      groups.each do |value , key|
        html_select << "<option value='#{key}'>#{value}</option>"
      end
    end
    respond_to do |format|
      format.csv { render :text => html_select ,:layout=>false ,:locals=>{:f=>@item} }
    end
  end

protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end
end
