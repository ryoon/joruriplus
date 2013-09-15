# encoding: utf-8
class Sns::Admin::Profiles::FilesController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    if params[:account]
      @created_user = Sns::Profile.find(:first, :conditions=>{:account=>params[:account]})
      return redirect_to "/_admin" if @created_user.blank?
      @u_role = false
      @u_role = true if @created_user.account==Core.profile.account
    end
  end

  def index
    @items = Sns::File.post_user(@created_user.id).is_friend_post(@is_friend).excludes(:is_project=>1).desc(:created_at).paginate(:page => params[:page], :per_page => 20)
  end

  def show
    @item = Sns::File.find(:first, :conditions=>{:_id=>params[:id]})
  end

  def new
    @item = Sns::File.new
    @item.created_user_id = Core.profile.id
  end

  def create
    @item = Sns::File.new
    items = Sns::File.any_in("_id"=>params[:ids])
    items.each do |file|
      file.update_attributes!(:privacy => params[:item][:privacy], :caption=>params[:item][:caption])
    end
    flash[:notice]="ファイルを追加しました。"
    return redirect_to sns_user_files_path(@created_user.account)
  end


  def edit
    @item = Sns::File.find(:first, :conditions=>{:_id=>params[:id]})
  end

  def update
    @item = Sns::File.find(:first, :conditions=>{:_id=>params[:id]})
    if @item.file_data_save(params, :update)
      range_change(params)
      flash[:notice]="ファイルを追加しました。"
      return redirect_to sns_user_file_path(@created_user.account,@item)
    else
      flash[:notice]="ファイルの追加に失敗しました。"
      return redirect_to :action => 'edit'
    end
  end

  def range_change(params)
    if params[:item][:privacy]=="group"
      pr_group_id = Core.user_group.id
    else
      pr_group_id = nil
    end
    post_item = Sns::Post.where(:kind=>"file").where(:file_ids=>params[:id]).where(:created_user_id=>Core.profile.id).first
    unless post_item.blank?
      post_item.privacy = params[:item][:privacy]
      post_item.pr_group_id = pr_group_id
      post_item.save(:validate=>false)
      other_ids = post_item.file_ids
      other_ids.delete(params[:id])
      other_ids.each do |o|
        other_item = Sns::File.find(o)
        if other_item
          other_item.privacy = params[:item][:privacy]
          other_item.pr_group_id = pr_group_id
          other_item.save(:validate=>false)
        end
      end
    end
  end

protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end

end
