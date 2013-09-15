# encoding: utf-8
class Sns::Admin::FriendProposalsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  include Sns::Controller::Setting
  include Sys::Lib::Mail::Address
  layout :select_layout

  def pre_dispatch
    @current = params[:cl] || "to"
    @class = "companion"
    @kind = params[:kind] || "friend"
  end

  def index
    @exclude_state = ["refused","recognized"]
    user_h =  {:to_user_id=>Core.profile.id}
    user_h = {:fr_user_id=>Core.profile.id} if @current == "fr"
    @items = Sns::FriendProposal.not_in("state"  => @exclude_state).where(user_h).k_call(@kind)
    @items = @items.desc(:created_at) if @items
  end

  def new
    @to_user = Sns::Profile.find(:first, :conditions=>{:_id=>params[:to_user_id]})
    if @to_user.blank?
      flash[:notice] = "存在しないユーザーです。"
      return redirect_to sns_friend_proposals_path
    end
    @item = Sns::FriendProposal.new
    @item.fr_user_id = Core.profile.id
    @item.to_user_id = @to_user.id
  end

  def create
    @to_user = Sns::Profile.find(:first, :conditions=>{:_id=>params[:item][:to_user_id]})
    if @to_user.blank?
      flash[:notice] = "存在しないユーザーです。"
      return redirect_to sns_friend_proposals_path
    end
    @item = Sns::FriendProposal.new(params[:item])
    @item.state="unread"
    @item.kind="friend"
    if @item.save
      proposal_send_mail
      return redirect_to sns_friend_proposals_path({:cl=>"fr"})
    else
      render :action=>:edit
      return
    end
  end

  def show
    @item = Sns::FriendProposal.find(params[:id])
    return if @item.fr_user.blank? || @item.to_user.blank?
    if @item.to_user_id == Core.profile.id && @item.state=="unread"
      @item.state = "read"
      @item.save(:validate=>false)
    end
    if @item.kind=="schedule"
      return redirect_to sns_schedule_path(@item.project.code,@item.schedule_id) unless @item.project.blank?
    end
  end

  def destroy
    @item = Sns::FriendProposal.find(:first, :conditions=>{:_id=>params[:id]})
    return redirect_to sns_friend_proposals_path if @item.fr_user_id != Core.profile.id
    @item.destroy
    return redirect_to sns_friend_proposals_path
  end

  def recognize_all
    return redirect_to sns_friend_proposals_path if params[:ids].blank?
    @items = Sns::FriendProposal.where(:_id.in=>params[:ids], :to_user_id=>Core.profile.id)
    return redirect_to sns_friend_proposals_path if @items.blank?
  end

  def reply_all
    return redirect_to sns_friend_proposals_path if params[:ids].blank?
    @item = Sns::FriendProposal.new
    @items = Sns::FriendProposal.where(:_id.in=>params[:ids], :to_user_id=>Core.profile.id)
    return redirect_to sns_friend_proposals_path if @items.blank?
    @items.each do |item|
      @item = item
      @item.state = "recognized"
      @item.reply_body=params[:item][:reply_body]
      if @item.save
        @item.recognize_proposal
        proposal_send_mail
      end
    end
    return redirect_to sns_friend_proposals_path
  end


  def recognize
    @item = Sns::FriendProposal.find(:first, :conditions=>{:to_user_id=>Core.profile.id, :_id=>params[:id]})
    return redirect_to sns_friend_proposals_path if @item.blank?
    return redirect_to sns_friend_proposals_path if @item.state == "refused" || @item.state == "recognized"
    if @item.kind=="project" || @item.kind=="project_manager" || @item.kind=="project_leave" || @item.kind=="project_join"
      if @item.kind=="project_leave"
        ind_kind = "leave"
      elsif @item.kind=="project_join"
        ind_kind = "join"
      else
        ind_kind = "invite"
      end
      redirect_path=  project_check(ind_kind,"recognized","recognize")
      return redirect_to redirect_path
    elsif @item.kind == "schedule"
      redirect_path=  project_check("schedule","recognized","recognize")
      return redirect_to redirect_path
    end
    @item.state = "recognized"
    @fr_user = @item.fr_user
  end

  def reply
    @item = Sns::FriendProposal.find(:first, :conditions=>{:to_user_id=>Core.profile.id, :_id=>params[:id]})
    return redirect_to sns_friend_proposals_path if @item.blank?
    @item.state = "recognized"
    @item.reply_body=params[:item][:reply_body]
    if @item.save
      @item.recognize_proposal
      flash[:notice]="友達申請を承認しました。"
      proposal_send_mail
      return redirect_to sns_friend_proposals_path
    else
      flash[:notice]="友達申請の承認に失敗しました。"
      return redirect_to sns_friend_proposals_path
    end
  end



  def refuse
    @item = Sns::FriendProposal.find(:first, :conditions=>{:to_user_id=>Core.profile.id, :_id=>params[:id]})
    return redirect_to sns_friend_proposals_path if @item.blank?
    return redirect_to sns_friend_proposals_path if @item.state == "refused" || @item.state == "recognized"
    if @item.kind=="project" || @item.kind=="project_manager" || @item.kind=="project_leave" || @item.kind=="project_join"
      if @item.kind=="project_leave"
        ind_kind = "leave"
      elsif @item.kind=="project_join"
        ind_kind = "join"
      else
        ind_kind = "invite"
      end
      redirect_path=  project_check(ind_kind,"refused","refuse")
      return redirect_to redirect_path
    elsif @item.kind == "schedule"
      redirect_path=  project_check("schedule","refused","refuse")
      return redirect_to redirect_path
    end
    @item.state = "refused"
    if @item.save
      flash[:notice]="友達申請を拒否しました。"
      return redirect_to sns_friend_proposals_path
    else
      flash[:notice]="友達申請の拒否に失敗しました。"
      return redirect_to sns_friend_proposals_path
    end
  end


  def project_check(kind, state, do_state)
    redirect_path = sns_friend_proposals_path({:kind=>kind})
    @project = Sns::Project.where(:_id=>@item.project_id).first
    if @project.blank?
      @item.state = "recognized"
      @item.save
      flash[:notice]="プロジェクトが削除されています。"
    else
      redirect_path = approval_sns_member_path(@item.project.code, @item,{:do=>do_state}) if kind!="schedule"
    end
    if kind=="schedule"
      @schedule = Sns::Schedule.where(:_id=>@item.schedule_id).first
      if @schedule.blank?
        flash[:notice]="スケジュールが削除されています。"
        @item.state = state
      else
        redirect_path = sns_schedule_path(@item.project.code,@item.schedule_id) unless @project.blank?
      end
    end
    @item.save
    return redirect_path
  end

  def package_proposal
    if params[:ids]
      proposal_ids =  params[:ids].dup
    else
      flash[:notice]="ユーザーを選択してください。"
      return redirect_to sns_sys_addresses_path
    end
    friend = Sns::Friend.where(:user_id=>Core.profile.id).first
    unless friend.blank?
      current_members = friend.friend_user_id.size
      proposal_members = proposal_ids.size
      if current_members + proposal_members > 500
        flash[:notice]="友達の人数制限(500人）をオーバーしています。"
        return redirect_to sns_sys_addresses_path
      end
    end
    @users = Sns::Profile.where(:_id.in=>proposal_ids)
  end

  def do_proposal
    proposal_ids =  params[:ids].dup
    @users = Sns::Profile.where(:_id.in=>proposal_ids)
    @users.each do |user|
      @item = Sns::FriendProposal.new(params[:item])
      @item.to_user_id = user.id
      @item.fr_user_id = Core.profile.id
      @item.state="unread"
      @item.kind="friend"
      proposal_send_mail if @item.save
    end
    return redirect_to sns_friend_proposals_path({:cl=>"fr"})
  end


  def package_recognize
    redirect_path = sns_friend_proposals_path({:kind=>@kind})
    if params[:ids].blank?
      flash[:notice]="申請が一件も選択されていません。"
      return redirect_to redirect_path
    end
    @items = Sns::FriendProposal.where(:_id.in=>params[:ids])
    if @items.blank?
      flash[:notice]="申請が一件も選択されていません。"
      return redirect_to redirect_path
    end
    @items.each do |item|
      @item = item
      if @item.kind=="friend"
        do_friend_proposal(params)
      elsif @item.kind=="project" || @item.kind=="project_manager" || @item.kind=="project_leave" || @item.kind=="project_join"
        @project = Sns::Project.where(:_id=>@item.project_id).first
        if @project.blank?
          @item.state = "recognized"
          @item.save
          next
        end
        if params[:do]=="recognize"
          @item.state="recognized"
          if @item.kind == "project" || @item.kind == "project_manager"
            @item.recognize_notice
            project_feed_post
          end
        else
          @item.state="refused"
        end
        if @item.kind == "project_leave"
          @item.leave_project(@item.state)
          membership = @project.members.where({:user_id=>@item.fr_user_id, :state=>"pre-disabled"}).first
          membership.state="enabled"
          membership.save
        elsif @item.kind =="project_join"
          @item.join_project(@item.state)
        end
      elsif @item.kind=="schedule"
        @project = Sns::Project.where(:_id=>@item.project_id).first
        @schedule= Sns::Schedule.where(:_id=>@item.schedule_id).first
        if @project.blank? || @schedule.blank?
          @item.state = "recognized"
          @item.save
          next
        end
        if params[:do]=="recognize"
          schedule_join(@schedule, "join")
          @item.state = "recognized"
        else
          schedule_join(@schedule, "absence")
          @item.state = "refused"
        end
      end
      @item.save
    end
    flash[:notice]="一括承認を行いました。"
    return redirect_to redirect_path
  end

  def do_friend_proposal(params)
    if params[:do]=="recognize"
      @item.recognize_proposal
      @item.state="recognized"
      proposal_send_mail
    else
      @item.state="refused"
    end
  end

  def schedule_join(schedule, join_state)
    if schedule.is_join?(Core.profile)
      user = schedule.members.where(:user_id => Core.profile.id).first
      user.state = join_state
      user.save
    else
      if join_state=="join"
        user = Sns::Member.new
        user.state = join_state
        user.user_id = Core.profile.id
        schedule.members << user
      end
    end
  end


protected

  def project_feed_post
    to_user = @item.to_user
    return if to_user.blank?
    message =  %Q(メンバー更新：#{to_user.name}さんが<a href="#{sns_project_path(@project.code)}" >#{@project.title}</a>に参加しました。)
    attribute = {
            :text =>message,
            :kind =>["project"],
            :privacy =>"project",
            :content_id=>[@item.id],
            :created_user_id=>to_user.id,
            :project_id=>@project.id,
            :is_project=>1
          }
    Sns::Post.create(attribute)
  end

  def proposal_send_mail
    fr_user = Sns::Profile.find(:first, :conditions=>{:id=>@item.fr_user_id})
    return if fr_user.blank?
    to_user = Sns::Profile.find(:first, :conditions=>{:id=>@item.to_user_id})
    return if to_user.blank?
    mail_fr = system_mail_addr
    message = ""
    config = display_items_config
    if @item.state=="unread"
      return if config[:proposal] != "on"
      mail_to = to_user.mail_addr
      subject = "#{fr_user.name}さんから#{Core.title}の友達申請がありました"
      message = "#{fr_user.name}（#{fr_user.group_name({:s_name=>false})}）さんから#{Core.title}の友達申請がありました。\n以下のURLを確認してください。\n"
      message +="http://#{env['HTTP_HOST']}#{sns_friend_proposal_path(@item)}\n"
    elsif @item.state=="recognized"
      return if config[:recognized] != "on"
      mail_to = fr_user.mail_addr
      subject = "#{to_user.name}さんに#{Core.title}の友達申請が受理されました"
      message = "#{to_user.name}（#{to_user.group_name({:s_name=>false})}）さんに#{Core.title}の友達申請が受理されました。\n以下のURLを確認してください。\n"
      message +="http://#{env['HTTP_HOST']}/_admin/sns/friends"
    end
    message += "\n\nこのメールアドレスは送信専用です。"
    return if mail_to.blank?
    send_mail(mail_fr, mail_to, subject, message)
  end

  def select_layout
    layout = "admin/sns/sns"
    layout
  end

end
