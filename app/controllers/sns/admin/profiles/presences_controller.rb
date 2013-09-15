class Sns::Admin::Profiles::PresencesController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout


  def index
    skip_layout
    #友達リストを取得
    friends = Sns::Friend.find(:first, :conditions=>{:user_id=>Core.profile.id})
    login_time = Time.now.ago(60 * 5)
    @list = []
    if friends
      presence_list = Sns::PresenceRecord.any_in("user_id"=>friends.friend_user_id).where(:presence_at.gt => login_time)
      p_user_id = []
      presence_list.each do |p|
        p_user_id << p.user_id
      end
      @list = Sns::Profile.where(:_id.in=>p_user_id).order_by([:sort_no, :asc]) unless p_user_id.blank?
    end
    respond_to do |format|
      format.html {  }
    end
  end

  def project
    skip_layout
    #友達リストを取得
    project_member = Sns::Project.find(:first, :conditions=>{:_id=>params[:p_id]})
    login_time = Time.now.ago(60 * 5)
    @list = []
    if project_member
      member_ids = []
      project_member.members.each do |m|
        member_ids << m.user_id
      end
      presence_list = Sns::PresenceRecord.any_in("user_id"=>member_ids).excludes(:user_id=>Core.profile.id).where(:presence_at.gt => login_time)
      p_user_id = []
      presence_list.each do |p|
        p_user_id << p.user_id
      end
      @list = Sns::Profile.where(:_id.in=>p_user_id).order_by([:sort_no, :asc]) unless p_user_id.blank?
    end
    respond_to do |format|
      format.html {  }
    end
  end

  def set
    skip_layout
    #在席状態を保存
    @item = Sns::PresenceRecord.find(:first, :conditions=>{:user_id=>Core.profile.id}) || Sns::PresenceRecord.new
    @item.user_id = Core.profile.id
    @item.presence_at = Time.now
    @item.save({:validate=>false})
    render :text=>"OK"
  end

  def stack
    #更新情報を取得
    skip_layout
    stack_time = Core.user.previous_login_date ? Core.user.previous_login_date.strftime('%Y-%m-%d %H:%M') : Time.now.strftime("%Y-%m-%d %H:%M")
    prof_friend = Core.profile.get_friend_info
    p_ids = Core.profile.project_select
    @stacks = Sns::Post.stack_call(prof_friend[1], p_ids).where(:created_at.gt=>stack_time).desc(:created_at)
    respond_to do |format|
      format.html { :layou }
    end
  end

protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end

end
