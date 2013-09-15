# encoding: utf-8
class Sns::Admin::FavoritesController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @kind  = params[:kind] || "post"
  end

  def index
    if @kind=="post"
      @post = Sns::Post.where(:_id=>params[:p_id]).first
    elsif @kind=="thread"
      @post = Sns::Thread.where(:_id=>params[:p_id]).first
    end
    @item = Sns::Favorite.new(:created_user_id=>Core.profile.id,:kind=>"thread",:name=>Core.user.name,:account=>Core.user.account)
    @post.favorites << @item
    @post.save
    respond_to do |format|
      format.js {  }
    end
  end

  def delete
    if @kind=="post"
      @post = Sns::Post.where(:_id=>params[:p_id]).first
    elsif @kind=="thread"
      @post = Sns::Thread.where(:_id=>params[:p_id]).first
    end
    return render :text => "NG not found" if @post.blank?
    @item = @post.favorites.find(:first, :conditions=>{:_id=>params[:id]})
    return render :text => "NG not found" if @item.blank?
    return render :text => "NG" if @item.created_user_id != Core.profile.id
    @item.destroy
    respond_to do |format|
      format.js {  }
    end
  end



  def post_feed
    post_user = @post.created_user
    return if post_user.blank?
    attribute = {
            :text =>"<a href='#{@post.doc_uri}' target='_blank' >あなたの投稿</a>にスターをつけました。" ,
            :kind =>["favorite"] ,
            :content_id=>[post_user.id,["fav_#{@kind}",@post.id],["fav",@item.id]],
            :privacy =>"notice",
            :created_user_id=>@item.created_user_id
          }
    Sns::Post.create(attribute)
  end

  def delete_feed
    feed = Sns::Post.where(:content_id=>["fav",@item.id]).first
    feed.destroy unless feed.blank?
  end


protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end

end
