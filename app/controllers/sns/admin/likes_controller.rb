# encoding: utf-8
class Sns::Admin::LikesController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @kind  = params[:kind] || "post"
  end

  def index
    if @kind=="post" || @kind=="report"
      @post = Sns::Post.where(:_id=>params[:p_id]).first
    elsif @kind=="thread"
      @post = Sns::Thread.where(:_id=>params[:p_id]).first
    else
      @post = Sns::Note.where(:_id=>params[:p_id]).first
    end
    return false if @post.blank?
    @dupulicate_check = @post.likes.find(:first, :conditions=>{:created_user_id=>Core.profile.id})
    if @dupulicate_check.blank?
      @item = Sns::Like.new(:created_user_id=>Core.profile.id,:kind=>@kind,:name=>Core.user.name,:account=>Core.user.account)
      @post.likes << @item
      @post.save
    end
    #post_feed
    respond_to do |format|
      format.js {  }
    end
  end

  def comment
    if @kind=="post" || @kind=="report"
      @post = Sns::Post.where(:_id=>params[:p_id]).first
    else
      @post = Sns::Note.where(:_id=>params[:p_id]).first
    end
    return false if @post.blank?
    @item = @post.comments.where(:_id=>params[:id]).first
    return false if @item.blank?
    users_arr = @item.like_user_id
    if users_arr.blank?
      users_arr = []
      users_arr << Core.profile.id
    else
      users_arr << Core.profile.id if users_arr.index(Core.profile.id).blank?
    end
    @item.like_user_id = users_arr
    @item.save
    respond_to do |format|
      format.js {  }
    end
  end

  def delete_comment
    if @kind=="post" || @kind=="report"
      @post = Sns::Post.where(:_id=>params[:p_id]).first
    else
      @post = Sns::Note.where(:_id=>params[:p_id]).first
    end
    return false if @post.blank?
    @item = @post.comments.where(:_id=>params[:id]).first
    return false if @item.blank?
    users_arr = @item.like_user_id
    if users_arr.blank?
      return false
    else
      users_arr.each_with_index{|u, i|
        users_arr.delete_at(i) if u == Core.profile.id
      }
      @item.like_user_id = users_arr
      @item.save
    end
  end

  def show_comment
    if @kind=="post" || @kind=="report"
      @post = Sns::Post.where(:_id=>params[:p_id]).first
    else
      @post = Sns::Note.where(:_id=>params[:p_id]).first
    end
    return false if @post.blank?
    @item = @post.comments.where(:_id=>params[:id]).first
    return false if @item.blank?
    @items = Sns::Profile.where(:_id.in=>@item.like_user_id) unless @item.like_user_id.blank?
    respond_to do |format|
      format.html { render :action=>"show", :layout=>false }
    end
  end

  def show
    if @kind=="post" || @kind=="report"
      @post = Sns::Post.where(:_id=>params[:id]).first
    elsif @kind=="thread"
      @post = Sns::Thread.where(:_id=>params[:id]).first
    else
      @post = Sns::Note.where(:_id=>params[:id]).first
    end
    unless @post.blank?
      @likes = @post.likes
      like_user_ids = []
      @likes.each do |l|
        like_user_ids << l.created_user_id
      end
      @items = Sns::Profile.where(:_id.in=>like_user_ids) unless like_user_ids.blank?
    end
    respond_to do |format|
      format.html { render :layout=>false }
    end
  end

  def delete
    if @kind=="post" || @kind=="report"
      @post = Sns::Post.where(:_id=>params[:p_id]).first
    elsif @kind=="thread"
      @post = Sns::Thread.where(:_id=>params[:p_id]).first
    else
      @post = Sns::Note.where(:_id=>params[:p_id]).first
    end
    return render :text => "NG not found" if @post.blank?
    @item = @post.likes.find(:first, :conditions=>{:_id=>params[:id]})
    return render :text => "NG not found" if @item.blank?
    return render :text => "NG" if @item.created_user_id != Core.profile.id
    delete_feed
    @item.destroy
    dupulicate_check = @post.likes.find(:all, :conditions=>{:created_user_id=>Core.profile.id})
    if dupulicate_check
      dupulicate_check.each do |d|
        d.destroy
      end
    end
    respond_to do |format|
      format.js {  }
    end
  end

  def post_feed
    post_user = @post.created_user
    return if post_user.blank?
    attribute = {
            :text =>"<a href='#{@post.doc_uri}' target='_blank' >あなたの投稿</a>にイイネ！しました。" ,
            :kind =>["like"] ,
            :content_id=>[post_user.id,["like_#{@kind}",@post.id],["like",@item.id]],
            :privacy =>"notice",
            :created_user_id=>@item.created_user_id
          }
    Sns::Post.create(attribute)
  end

  def delete_feed
    feed = Sns::Post.where(:content_id=>["like",@item.id]).first
    feed.destroy unless feed.blank?
  end

protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end

end
