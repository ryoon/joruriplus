# encoding: utf-8
class Sys::Admin::UsersController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def index
    @item = Sys::User.new # for search
    @item.in_group_id = params[:s_group_id]

    item = Sys::User.new
    item.search params
    item.page  params[:page], params[:limit]
    item.order params[:sort], "LPAD(account, 15, '0')"
    @items = item.find(:all)
    _index @items
  end

  def show
    @item = Sys::User.new.find(params[:id])
    return error_auth unless @item.readable?

    _show @item
  end

  def new
    @item = Sys::User.new({
      :state       => 'enabled',
      :ldap        => '0',
      :auth_no     => 2
    })
  end

  def create
    @item = Sys::User.new(params[:item])
    update_profile
    _create(@item)
  end

  def update
    @item = Sys::User.new.find(params[:id])
    @item.attributes = params[:item]
    update_profile
    _update(@item)
  end

  def destroy
    @item = Sys::User.new.find(params[:id])
    _destroy(@item)
  end

  def update_profile
    user_sort_no = @item.sort_no
    user_sort_no = "no_number" if @item.sort_no.blank?
    n_prof           = Sns::Profile.find(:first, :conditions=>{:account=>@item.account}) || Sns::Profile.new
    n_prof.account   = @item.account
    n_prof.user_id   = @item.id
    n_prof.name      = @item.name
    n_prof.mail_addr = @item.email
    n_prof.kana      = @item.kana
    n_prof.sort_no   = user_sort_no
    n_prof.save(:validate => false)
  end

end
