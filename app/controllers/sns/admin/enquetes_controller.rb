# encoding: utf-8
class Sns::Admin::EnquetesController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
    @edit_current  = params[:cl] || "post"
    @post = Sns::Post.find(:first, :conditions=>{:_id=>params[:parent]})
    return redirect_to "/_admin" if @post.blank?
  end


  def create
    @enquete = @post.enquete
    @enquete.total += 1
    opt = @enquete.select_options.where(:_id=>params[:answer]).first
    opt.count += 1
    opt.user_ids << Core.profile.id
    @enquete.save
    respond_to do |format|
      format.js {  }
    end
  end



  def feed_post(post,par_item,coment_id)
    post_user = Sns::Profile.where(:_id=>par_item[:created_user_id]).first
    return if post_user.blank?
    return if post.privacy == "notice"
    if post.privacy=="project_activity"
      kind = ["activity_comment"]
      privacy = "project_activity"
      content_id = [["comment",coment_id],["parent",post.id]]
      is_project = 1
      project_id = nil
      parent_project = post.project
      if parent_project
        project_id = parent_project.id
        post_body = %Q(「#{parent_project.title}」の)
        post_body += %Q(<a href="#{sns_report_path(post.project.code, post)}" target="_blank">アクティビティ</a>にコメントがありました。)
      else
        post_body = %Q(あなたの投稿にコメントしました。※プロジェクトが削除されています。)
      end
    else
      return if post_user.id == post.created_user.id
      kind = ["comment"]
      privacy = "notice"
      is_project = nil
      project_id = nil
      content_id = [post.created_user.id, ["comment",coment_id],["parent",post.id]]
      post_body = %Q(<a href="#{sns_post_path(post)}" target="_blank">あなたの投稿</a>にコメントしました。)
    end
    attribute = {
            :text =>post_body ,
            :kind =>kind ,
            :content_id=>content_id,
            :privacy =>privacy,
            :created_user_id=>post_user.id,
            :is_project=>is_project,
            :project_id=>project_id
          }
    Sns::Post.create(attribute)
  end


  def destroy
    @item = @post.comments.find(:first, :conditions=>{:_id=>params[:id]})
    if @item.blank?
      render :text => "NG"
      return
    else
      @item.destroy
      render :text => "#{@item.id}"
      return
    end
  end

  def delete
    @item = @post.comments.find(:first, :conditions=>{:_id=>params[:id]})
    is_comment_editable = false
    is_comment_editable = true if @item.created_user_id == Core.profile.id
    if @post.privacy=="all"
      created_user = @item.created_user
      created_user_group = created_user.user_group unless created_user.blank?
      is_comment_editable = true if created_user_group.id == Core.user_group.id unless created_user_group.blank?
    end
    return render :text => "NG no auth" if is_comment_editable==false unless Core.user.has_auth?(:manager)
    if @item.blank?
      render :text => "NG not found"
      return
    else
      @item.destroy
      feed = Sns::Post.where(:content_id=>["comment",@item.id]).first
      feed.destroy unless feed.blank?
      render :text => "#{@item.id}"
      return
    end
  end

protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end

end
