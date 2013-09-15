# encoding: utf-8
class Sns::Admin::PostsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  include Sns::NewsfeedHelper
  layout :select_layout

  def pre_dispatch
    @cat = case params[:cat]
    when "note"
      "note"
    when "file"
      "file"
    when "photo"
      "photo"
    when "video"
      "video"
    when "news"
      "news"
    when "enquete"
      "enquete"
    when "favorite"
      "favorite"
    else
      ""
    end
    @subfeed = params[:subfeed] || "newsfeed"
    @fav = params[:fav].blank? ? "0" : params[:fav]

  end

  #tweet関連
  def show
    @item = Sns::Post.where(:_id=>params[:id]).first
    return http_error(404) if @item.blank?
    return redirect_to "/_admin" unless @item.auth_check
    @feed_user = @item.created_user
  end

  def edit
    @item = Sns::Post.where(:_id=>params[:id]).first
    return http_error(404) if @item.blank?
  end

  def show_photos
    @item = Sns::Post.where(:_id=>params[:id]).first
    return http_error(404) if @item.blank?
    @photos = Sns::Photo.where(:_id.in=>@item.photo_ids) unless @item.photo_ids.blank?
    respond_to do |format|
      format.html { render :layout=>false }
    end
  end

  def publish
    @item = Sns::Post.where(:_id=>params[:id]).first
    if @item
      @item.privacy = params[:privacy]
      @item.pr_group_id = Core.user_group.id if params[:privacy]=="group"
      @item.save
      file_ranges
      custom_group_members = @item.custom_group_members
      @publiched_members = feed_publiched_members(@item)
    end
    respond_to do |format|
      format.js {  }
    end
  end
  def file_ranges
    @item.photo_ids.each do |f|
      photo_item = Sns::Photo.find(:first, :conditions=>{:_id=>f})
      photo_item.update_attributes!(:privacy => @item.privacy, :pr_group_id => @item.pr_group_id ) if photo_item
    end if @item.photo_ids
    @item.file_ids.each do |f|
      file_item = Sns::File.find(:first, :conditions=>{:_id=>f})
      file_item.update_attributes!(:privacy => @item.privacy, :pr_group_id => @item.pr_group_id ) if file_item
    end if @item.file_ids
    @item.video_ids.each do |f|
      video_item = Sns::Video.find(:first, :conditions=>{:_id=>f})
      video_item.update_attributes!(:privacy => @item.privacy, :pr_group_id => @item.pr_group_id ) if video_item
    end if @item.video_ids
  end

  def delete
    @item = Sns::Post.where(:_id=>params[:id]).first
    return render :text => "NG" unless @item.is_deletable? if @item.privacy != "project_activity"
    if @item.blank?
      render :text => "NG"
      return
    else
      @item.destroy
      delete_comments
      render :text => "#{@item.id}"
      return
    end
  end

  def delete_comments
    Sns::Post.destroy_all(:conditions=>{:content_id=>["parent",@item.id]})
  end

  def destroy
    @item = Sns::Post.where(:_id=>params[:id]).first
    if @item.blank?
      render :text => "NG"
      return
    else
      @item.destroy
      render :text => "#{@item.id}"
      return
    end
  end

  def published_user
    @use_friend_list = true
    @item = Sns::Post.where(:_id=>params[:id]).first
    return http_error(404) if @item.blank?
    return render :text => "限定公開ではありません。" unless @item.is_limited?
    @created_user = @item.created_user
    if @item.privacy == "select"
      @created_user = @item.created_user
      @items = Sns::Profile.any_of({:_id.in=>@item.publised_user_id},{:_id=>@created_user.id}) if !@item.publised_user_id.blank?
    elsif @item.privacy == "friend"
      @items = Sns::Profile.any_of({:_id.in=>@created_user.get_friend_info[1]},{:_id=>@created_user.id})  unless @created_user.blank?
    elsif @item.privacy == "group"
      @items = Sns::Profile.get_user_select(@item.pr_group_id,nil,{:profile_select=>1})
    else
      @custom_group = Sns::CustomGroup.where(:sequence=>@item.privacy, :user_id=>@item.created_user_id).first
      @items = Sns::Profile.any_of({:_id.in=>@custom_group.friend_user_id},{:_id=>@created_user.id}) unless @custom_group.blank?
    end
    respond_to do |format|
      format.html { render :layout=>false }
    end
  end

  def select_user
    @use_friend_list = true
    @item = Sns::Post.where(:_id=>params[:id]).first
    return http_error(404) if @item.blank?
    @members = Sns::Profile.where(:_id.in=>@item.publised_user_id) if !@item.publised_user_id.blank? &&  @item.privacy=="select"
    respond_to do |format|
      format.html { render :layout=>false }
    end
  end

  def set_user
    @use_friend_list = true
    @item = Sns::Post.where(:_id=>params[:id]).first
    return render :text=>"not found" if @item.blank?
    published_users_id = []
    unless params[:user_id].blank?
      params[:user_id] = params[:user_id].dup
      selected_users = Sns::Profile.where(:_id.in=>params[:user_id])
      selected_users.each do |u|
        published_users_id << u.id
      end unless selected_users.blank?
    end
    @item.privacy="select"
    @item.publised_user_id = published_users_id
    @item.save
    @publiched_members = feed_publiched_members(@item)
    custom_group_members = @item.custom_group_members
    respond_to do |format|
      format.js { render :layout=>false }
    end
  end

  def group_field
    html_select = ""
    if params[:p_id].blank? || params[:p_id].to_i == 0
      groups = nil
    else
      groups = Sys::Group.find(:all , :conditions=>["parent_id =? AND state = ? AND level_no = ?",params[:p_id],"enabled",3],:order=>:code)
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

  def users_field
    html_select = ""
    if params[:p_id]=="0"
      html_select = friends_list
    else
      html_select = user_list(params[:p_id], params[:g_id])
    end
    respond_to do |format|
      format.csv { render :text => html_select ,:layout=>false ,:locals=>{:f=>@item} }
    end
  end

  def user_list(p_id, g_id)
    ret = ""
    if g_id.blank?
      group_id = p_id
    else
      group_id = g_id
    end
    users = Sns::Profile.get_user_select(group_id,nil,{:select=>true})
    if users
      users.each do |value , key|
        ret << "<option value='#{key}'>#{value}</option>"
      end
    end
    return ret
  end

  def friends_list
    ret = ""
    friends = Core.profile.get_friend_info[0]
    if friends
      friends.each do |f|
        ret << "<option value='#{f.id}'>#{f.name}</option>"
      end
    end
    return ret
  end


  ##ajax 処理
  def create
    @feed_body_ids = []
    @item = Core.profile
    @post = true
    @feeds = nil
    @feed = nil
    @kind = ["tweet"]
    @errors = nil
    photo_ids = []
    file_ids = []
    video_ids = []
    enquete_id = nil
    published_users_id = []
    unless params[:user_id].blank?
      params[:user_id] = params[:user_id].dup
      selected_users = Sns::Profile.where(:_id.in=>params[:user_id])
      selected_users.each do |u|
        published_users_id << u.id
      end unless selected_users.blank?
    end

    if params[:tweet][:privacy]=="group"
      pr_group_id = Core.user_group.id
    else
      pr_group_id = nil
    end
    unless params[:file_ids].blank?
      @kind << "file"
      items = Sns::File.any_in("_id"=>params[:file_ids])
      items.each do |file|
        file_ids << file.id
        file.update_attributes!(:privacy => params[:tweet][:privacy],
        :pr_group_id => pr_group_id,
        :is_project=>params[:is_project].to_i,
        :project_id=>params[:project_id],
        :publised_user_id=>published_users_id,
        :created_user_name => Core.user.name,
        :created_group_name => Core.user_group.name,
        :created_group_code => Core.user_group.code,
        :created_group_id => Core.user_group.id)
      end
    end
    unless params[:photo_ids].blank?
      @kind << "photo"
      items = Sns::Photo.any_in("_id"=>params[:photo_ids])
      items.each do |photo|
        photo_ids << photo.id
        photo.update_attributes!(:privacy => params[:tweet][:privacy],
        :pr_group_id => pr_group_id,
        :is_project=>params[:is_project].to_i,
        :project_id=>params[:project_id],
        :publised_user_id=>published_users_id,
        :created_user_name => Core.user.name,
        :created_group_name => Core.user_group.name,
        :created_group_code => Core.user_group.code,
        :created_group_id => Core.user_group.id)
      end
    end
    unless params[:tweet][:url].blank?
      @kind << "video"
      video_uri = params[:tweet][:url]
      video_uri = video_uri.gsub(/<iframe .*?src=(\"|\')(.*?)(\"|\') .*?>.*?<\/iframe>/iom, '\2') if video_uri=~/<iframe/
      video_uri = video_uri.gsub(/<script .*?src=(\"|\')(.*?)(\"|\') .*?>.*?<\/script>/iom, '\2') if video_uri =~ /<script /
      f_a_id = ""
      unless params[:project_id].blank?
        @project = Sns::Project.where(:_id=>params[:project_id]).first
        f_album = Sns::Album.where(:kind=>"video" , :project_id => @project.id).first
        if f_album
          f_a_id = f_album.id
        else
          new_f_album = Sns::Album.create(:kind=>"video" , :project_id => @project.id, :name => "#{@project.title}の動画")
          f_a_id = new_f_album.id
        end
        project_id = @project.id
      end
      item = Sns::Video.new({
          :url => video_uri,
          :width => 320,
          :height => 240,
          :privacy=>params[:tweet][:privacy],
          :pr_group_id => pr_group_id,
          :created_user_id=>Core.profile.id,
          :publised_user_id=>published_users_id
        })
        if f_a_id.blank?
          item.album_id = item.album_exist("ニュースフィード",Core.profile.id)
        else
          item.album_id = f_a_id
        end
        unless @project.blank?
          item.is_project = 1
          item.project_id = @project.id
        end
      if item.save
        video_ids = [item.id]
      else
        @post = false
        @erros = "指定した動画は、すでに登録されています。"
      end
    end
    unless params[:enq_opts].blank?
      enq_opts = params[:enq_opts].delete_if{|x| x.empty?}
      unless enq_opts.blank?
        @kind << "enquete"
        enq_opt_items=[]
        enq_opts.each{|opt| enq_opt_items << Sns::EnqueteOption.new({:name=>opt,:count=>0,:user_ids=>[]})}
        item = Sns::Enquete.new({
          :privacy=>params[:tweet][:privacy],
          :pr_group_id=>pr_group_id,
          :created_user_id=>Core.profile.id,
          :publised_user_id=>published_users_id,
          :is_project=>params[:is_project].to_i,
          :project_id=>params[:project_id],
          :total=>0,
          :select_options=>enq_opt_items
        })

        if item.save
          enquete_id = item.id
        else
          @post = false
          @erros = "アンケートが登録できませんでした。"
        end
      end
    end
    if @post==true
      attribute = {
              :text =>params[:tweet][:body],
              :kind =>@kind,
              :photo_ids=>photo_ids,
              :file_ids=>file_ids,
              :video_ids=>video_ids,
              :enquete_id=>enquete_id,
              :privacy => params[:tweet][:privacy],
              :created_user_id=>Core.profile.id,
              :is_project=>params[:is_project].to_i,
              :project_id=>params[:project_id],
              :publised_user_id=>published_users_id
            }
      @feed = Sns::Post.new(attribute)
      @feed.save
    end
    unless params[:date].blank?
      prof_friend = Core.profile.get_friend_info
      p_ids = Core.profile.project_select
      if @cat.blank?
        if @subfeed=="public" || @subfeed=="all" || @subfeed=="group"
          @pr_id = @subfeed
          @feeds = Sns::Post.public_stream(@subfeed,{:fav=>@fav}).gt_sequence(params[:date])
        elsif @subfeed == "member"
          @pr_id = "friend"
          @feeds = Sns::Post.custom_call(prof_friend[1], nil,{:fav=>@fav}).gt_sequence(params[:date])
        elsif @subfeed=="project"
          @pr_id = "project"
          @is_project = {:project=>1}
          unless params[:project_id].blank?
            @project = Sns::Project.where(:_id=>params[:project_id]).first
            @feeds = Sns::Post.project_report(@project.id,@fav).gt_sequence(params[:date]).desc(:sequence)
          end
        elsif @subfeed =~ /^cg_(\d+)$/
          @pr_id = "#{$1}"
          custom_friends = []
          c_group = Sns::CustomGroup.where(:sequence=>@pr_id.to_i, :user_id=>Core.profile.id).first
          custom_friends = c_group.friend_user_id unless c_group.blank?
          if custom_friends.blank?
            @feeds = nil
          else
            @feeds = Sns::Post.custom_call(custom_friends, nil,{:custom_group_id=>@pr_id.to_i,:fav=>@fav}).gt_sequence(params[:date])
          end
        else
          @feeds = Sns::Post.p_call(prof_friend[1],p_ids,{:fav=>@fav}).gt_sequence(params[:date]).desc(:sequence)
        end
      else
        if @cat=="news"
          @feeds = Sns::Post.call_my_news(p_ids,Core.profile.id , Core.user_group.id,{:friend_user_id=>prof_friend[1],:fav=>@fav}).gt_sequence(params[:date]).desc(:sequence)
        else
          if @subfeed=="project"
            @pr_id = "project"
            @is_project = {:project=>1}
            unless params[:project_id].blank?
              @project = Sns::Project.where(:_id=>params[:project_id]).first
              @feeds = Sns::Post.project_report(@project.id,@fav).gt_sequence(params[:date]).desc(:sequence)
            end
          else
            @feeds = Sns::Post.k_call(@cat).p_call(prof_friend[1],p_ids,{:fav=>@fav}).gt_sequence(params[:date]).desc(:sequence)
          end
        end
      end
    end
    respond_to do |format|
      format.js{ render :layout => false }
    end
  end


  def index
    @feed_body_ids = []
    @feeds = nil
    @state_str=""
    @date_str = ""
    unless params[:date].blank?
      prof_friend = Core.profile.get_friend_info
      p_ids = Core.profile.project_select
      if @cat.blank?
        if @subfeed=="public" || @subfeed=="all" || @subfeed=="group"
          @pr_id = @subfeed
          @feeds = Sns::Post.public_stream(@subfeed,{:fav=>@fav}).lt_sequence(params[:date]).display_limit.desc(:sequence)
        elsif @subfeed == "member"
          @pr_id = "friend"
          prof_friend = Core.profile.get_friend_info
          p_ids = Core.profile.project_select
          @feeds = Sns::Post.custom_call(prof_friend[1], nil,{:fav=>@fav}).lt_sequence(params[:date]).display_limit.desc(:sequence)
        elsif @subfeed=="project"
          @pr_id = "project"
          unless params[:project_id].blank?
            @project = Sns::Project.where(:_id=>params[:project_id]).first
            @feeds = Sns::Post.project_report(@project.id,@fav).lt_sequence(params[:date]).display_limit.desc(:sequence)
          end
        elsif @subfeed =~ /^cg_(\d+)$/
          @pr_id = "#{$1}"
          custom_friends = []
          c_group = Sns::CustomGroup.where(:sequence=>@pr_id.to_i, :user_id=>Core.profile.id).first
          custom_friends = c_group.friend_user_id unless c_group.blank?
          if custom_friends.blank?
            @feeds = nil
          else
            @feeds = Sns::Post.custom_call(custom_friends, nil,{:custom_group_id=>@pr_id.to_i,:fav=>@fav}).lt_sequence(params[:date]).display_limit.desc(:sequence)
          end
        else
          @feeds = Sns::Post.p_call(prof_friend[1], p_ids,{:fav=>@fav}).lt_sequence(params[:date]).display_limit.desc(:sequence)
        end
      else
        if @cat=="news"
          @feeds = Sns::Post.call_my_news(p_ids,Core.profile.id , Core.user_group.id,{:friend_user_id=>prof_friend[1],:fav=>@fav}).lt_sequence(params[:date]).display_limit.desc(:sequence)
        else
          @feeds = Sns::Post.k_call(@cat).p_call(prof_friend[1],p_ids,{:fav=>@fav}).lt_sequence(params[:date]).display_limit.desc(:sequence)
        end
      end
      @date_str = @feeds.last.sequence unless @feeds.blank?
    end
    respond_to do |format|
      format.js { render :layout => false }
    end
  end

  def cat_ind
    @feed_body_ids = []
    prof_friend = Core.profile.get_friend_info
    @feeds = nil
    @state_str=""
    @date_str = ""
    p_ids = Core.profile.project_select
    if @cat.blank?
      if @subfeed=="public" || @subfeed=="all" || @subfeed=="group"
          @pr_id = @subfeed
        @feeds = Sns::Post.public_stream(@subfeed).display_limit.desc(:sequence)
      elsif @subfeed == "member"
      @pr_id = "friend"
        prof_friend = Core.profile.get_friend_info
        @feeds = Sns::Post.custom_call(prof_friend[1], nil).display_limit.desc(:sequence)
      elsif @subfeed=="project"
        @pr_id = "project"
        unless params[:project_id].blank?
          @project = Sns::Project.where(:_id=>params[:project_id]).first
          @feeds = Sns::Post.project_report(@project.id,@fav).display_limit.desc(:sequence) unless params[:project_id].blank?
        end
      elsif @subfeed =~ /^cg_(\d+)$/
        @pr_id = "#{$1}"
        custom_friends = []
        c_group = Sns::CustomGroup.where(:sequence=>@pr_id.to_i, :user_id=>Core.profile.id).first
        custom_friends = c_group.friend_user_id unless c_group.blank?
        if custom_friends.blank?
          @feeds = nil
        else
          @feeds = Sns::Post.custom_call(custom_friends, nil,{:custom_group_id=>@pr_id.to_i}).display_limit.desc(:sequence)
        end
      else
        prof_friend = Core.profile.get_friend_info
        p_ids = Core.profile.project_select
        @feeds = Sns::Post.p_call(prof_friend[1], p_ids).display_limit.desc(:sequence)
      end
    else
      if @cat=="news"
        @feeds = Sns::Post.call_my_news(p_ids,Core.profile.id , Core.user_group.id,{:friend_user_id=>prof_friend[1]}).display_limit.desc(:sequence)
      else
        @feeds = Sns::Post.k_call(@cat).p_call(prof_friend[1],p_ids).display_limit.desc(:sequence)
      end
    end
    @date_str = @feeds[@feeds.length - 1].sequence unless @feeds.blank?
    respond_to do |format|
      format.js { render :layout => false }
    end
  end

  def list
    @feed_body_ids = []
    @feeds = nil
    @state_str=""
    @item  = Sns::Profile.find(:first, :conditions => {:account => params[:account]} )
    return @feeds if @item.blank?
    @friends = @item.show_friends
    prof_friend = @item.get_friend_info
    @is_friend = @item.is_friend?(Core.profile)
    if params[:date].blank?
      @date_str = ""
    else
      date = params[:date].to_i
      if @cat.blank?
        if Core.user.has_auth?(:manager) && @item.id != Core.profile.id
          profile_group = @item.user_group
          p_ids = @item.project_select
          @feeds = Sns::Post.call_my_news(p_ids, @item.id , profile_group.id,{:friend_user_id=>prof_friend[1]}).lt_sequence(date).display_limit.desc(:sequence)
        else
          my_friend = Core.profile.get_friend_info
          my_group = Core.profile.user_group
          my_p_ids = Core.profile.project_select
          @feeds = Sns::Post.call_friend_news(@is_friend,@item ,my_p_ids, @item.id , my_group.id,{:friend_user_id=>my_friend[1]}).lt_sequence(date).display_limit.desc(:sequence)
        end
      else
        @feeds = Sns::Post.post_user(@item.id).k_call(@cat).is_friend_post(@is_friend,@item).lt_sequence(date).display_limit.desc(:sequence)
      end
      @date_str = @feeds[@feeds.length - 1].sequence unless @feeds.blank?
    end
    respond_to do |format|
      format.js { render :layout => false }
    end
  end



  def refresh
    @feed_body_ids = []
    @feeds = nil
    if params[:date]
      @date_str = params[:date]
      if params[:user_id].blank?
        @item = Core.profile
        prof_friend = Core.profile.get_friend_info
        p_ids = Core.profile.project_select
        if @cat.blank?
          if @subfeed=="public" || @subfeed=="all" || @subfeed=="group"
            @pr_id = @subfeed
            @feeds = Sns::Post.public_stream(@subfeed,{:fav=>@fav}).gt_sequence(@date_str).desc(:sequence)
          elsif @subfeed == "member"
            @pr_id = "friend"
            prof_friend = Core.profile.get_friend_info
            @feeds = Sns::Post.custom_call(prof_friend[1], nil,{:fav=>@fav}).gt_sequence(@date_str).desc(:sequence)
          elsif @subfeed=="project"
            @pr_id = "project"
            unless params[:project_id].blank?
             @project = Sns::Project.where(:_id=>params[:project_id]).first
             @feeds = Sns::Post.project_report(@project.id,@fav).gt_sequence(@date_str).desc(:sequence)
            end
          elsif @subfeed =~ /^cg_(\d+)$/
            @pr_id = "#{$1}"
            custom_friends = []
            c_group = Sns::CustomGroup.where(:sequence=>@pr_id.to_i, :user_id=>Core.profile.id).first
            custom_friends = c_group.friend_user_id unless c_group.blank?
            if custom_friends.blank?
              @feeds = nil
            else
              @feeds = Sns::Post.custom_call(custom_friends, nil,{:custom_group_id=>@pr_id.to_i,:fav=>@fav}).gt_sequence(@date_str).desc(:sequence)
            end
          else
            prof_friend = Core.profile.get_friend_info
            p_ids = Core.profile.project_select
            @feeds = Sns::Post.p_call(prof_friend[1], p_ids,{:fav=>@fav}).gt_sequence(@date_str).desc(:sequence)
          end
        else
          if @cat=="news"
            @feeds = Sns::Post.call_my_news(p_ids, Core.profile.id , Core.user_group.id,{:friend_user_id=>prof_friend[1],:fav=>@fav}).gt_sequence(@date_str).desc(:sequence)
          else
            @feeds = Sns::Post.k_call(@cat).p_call(prof_friend[1],p_ids,{:fav=>@fav}).gt_sequence(@date_str).desc(:sequence)
          end
        end
      else
        @item = Sns::Profile.find( :first, :conditions => {:account => params[:user_id]} )
        @is_friend = @item.is_friend?(Core.profile)
        if @cat.blank?
          if Core.profile.id != @item.id && Core.user.has_auth?(:manager)
            profile_group = @item.user_group
            p_ids = @item.project_select
            prof_friend = @item.get_friend_info
            @feeds = Sns::Post.call_my_news(p_ids, @item.id , profile_group.id,{:friend_user_id=>prof_friend[1]}).gt_sequence(@date_str).desc(:sequence)
          else
            my_friend = Core.profile.get_friend_info
            my_group = Core.profile.user_group
            my_p_ids = Core.profile.project_select
            @feeds = Sns::Post.call_friend_news(@is_friend,@item ,my_p_ids, @item.id , my_group.id,{:friend_user_id=>my_friend[1]}).gt_sequence(@date_str).desc(:sequence)
          end
        else
          @feeds = Sns::Post.k_call(@cat).post_user(@item.id).is_friend_post(@is_friend,@item).gt_sequence(@date_str).desc(:sequence)
        end
      end
    end
    respond_to do |format|
      format.js { render :layout => false }
    end
  end


protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end

end
