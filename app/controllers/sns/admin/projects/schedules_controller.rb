# -*- encoding: utf-8 -*-
class Sns::Admin::Projects::SchedulesController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  include Sns::Controller::Util
  layout :select_layout

  def pre_dispatch
    @project = Sns::Project.find(:first, :conditions=>{:code=>params[:parent]})
    return redirect_to sns_projects_path if @project.blank?
    return redirect_to sns_projects_path if @project.auth_check==false
    @project_code = @project.code
    @class = "schedule"
    @today    = Date.today
    @min_date = Date.new(@today.year, @today.month, 1) << 0
    @max_date = Date.new(@today.year, @today.month, 1) >> 11
    @node_uri = sns_schedules_path(@project_code)
  end

  def index
    params[:year]  = params[:year] || @today.strftime("%Y").to_s
    params[:month] = params[:month] || @today.strftime("%m").to_s
    return index_monthly
  end


  def index_monthly
    return http_error(404) unless validate_date

    @sdate = "#{@year}-#{@month}-01"
    @edate = (Date.new(@year, @month, 1) >> 1).strftime('%Y-%m-%d')
    @st_time = string_to_time(@sdate)
    @calendar = Util::Date::Calendar.new(@year, @month,{:form_w=>"mon"})
    @calendar.month_uri = "#{@node_uri}?year=:year&month=:month"
    @items = {}

    @calendar.days.each{|d| @items[d[:date]] = [] if d[:month].to_i == @month }
    events = Sns::Schedule.where(:project_id=>@project.id).where({:st_at.gt=>@sdate,:ed_at.lt=>@edate}).asc(:st_at)
    events.each do |ev|
      @items[ev.st_at.strftime("%Y-%m-%d").to_s] << ev
    end
    @schedule_items = @items

    @page_link = {}
    @page_link[:prev_label] = "&lt;前の月"
    @page_link[:next_label] = "次の月&gt;"
    @page_link[:prev_uri]   = @calendar.prev_month_uri
    @page_link[:next_uri]   = @calendar.next_month_uri

    render :action => "index_monthly"
  end

  def daily
    return http_error(404) if params[:st_date].blank?
    @st_date = string_to_date(params[:st_date])
    @st_str = string_to_time(params[:st_date]).strftime('%Y-%m-%d')
    @sdate = string_to_time(%Q(#{@st_str} 00:00:00))
    @edate = string_to_time(%Q(#{@st_str} 23:59:59))
    @items = Sns::Schedule.where(:project_id=>@project.id).where({:st_at.gt=>@sdate,:ed_at.lt=>@edate}).asc(:st_at)
    @st_year = @st_date.year
    @st_month = @st_date.month
    @st_day = @st_date.day
  end

  def new
    @st_date = @today
    @st_date = string_to_time(params[:st_date]) unless params[:st_date].blank?
    @item = Sns::Schedule.new({
      :project_id => @project.id,
      :st_at => string_to_time(%Q(#{@st_date.strftime('%Y-%m-%d')} 09:00:00)),
      :ed_at => string_to_time(%Q(#{@st_date.strftime('%Y-%m-%d')} 10:00:00)),
      :created_user_id=>Core.profile.id,
      :creator_group_id=>Core.user_group.id
      })
    @users = @project.members_select
    @members = [Core.profile]
  end

  def create
    @users = @project.members_select
    if params[:user_id]
      params[:user_id] = params[:user_id].uniq
      @members = Sns::Profile.any_in("_id" => params[:user_id])
    end
    @st_date = @today
    @st_date = string_to_time(params[:c_date]) if params[:c_date]
    _params = validate_params params
    @item = Sns::Schedule.new(_params[:item])
    if @item.save_with_rels(_params, :create)
      flash[:notice]="スケジュールを登録しました。"
      return redirect_to sns_schedules_path(@project_code)
    else
      render :action=>"new"
      return
    end
  end

  def edit
    @item = Sns::Schedule.find(params[:id])
    @st_date = @item.st_at
    p_members = @item.members
    @members = []
    p_members.each do |p|
      user = Sns::Profile.find(:first, :conditions=>{:_id=>p.user_id})
      @members << user unless user.blank?
    end if p_members
    @users = @project.members_select
  end

  def update
    @users = @project.members_select
    if params[:user_id]
      params[:user_id] = params[:user_id].uniq
      @members = Sns::Profile.any_in("_id" =>params[:user_id])
    end
    _params = validate_params params

    @st_date = @today
    @st_date = string_to_time(params[:c_date]) if params[:c_date]
    @item = Sns::Schedule.find(_params[:id])

    @item.update_attributes(_params[:item])
    if @item.save_with_rels(_params, :update)
      flash[:notice]="スケジュールを編集しました。"
      return redirect_to sns_schedules_path(@project_code)
    else
      render :action=>"edit"
      return
    end
  end

  def show
    @item = Sns::Schedule.find(:first, :conditions=>{:_id=>params[:id]})
    @members = @item.schedule_join_members
    return http_error(404) if @item.blank?
  end

  def destroy
    @item = Sns::Schedule.find(params[:id])
    @item.destroy
    return redirect_to sns_schedules_path(@project_code)
  end

  def validate_params(params_i)
    params_o = params_i
    st_at_str = %Q(#{params[:c_date]} #{params_o[:item]['st_at(4i)']}:#{params_o[:item]['st_at(5i)']})
    params_o[:item].delete "st_at(1i)"
    params_o[:item].delete "st_at(2i)"
    params_o[:item].delete "st_at(3i)"
    params_o[:item].delete "st_at(4i)"
    params_o[:item].delete "st_at(5i)"
    params_o[:item][:st_at]= st_at_str
    ed_at_str = %Q(#{params[:c_date]} #{params_o[:item]['ed_at(4i)']}:#{params_o[:item]['ed_at(5i)']})
    params_o[:item].delete "ed_at(1i)"
    params_o[:item].delete "ed_at(2i)"
    params_o[:item].delete "ed_at(3i)"
    params_o[:item].delete "ed_at(4i)"
    params_o[:item].delete "ed_at(5i)"
    params_o[:item][:ed_at]= ed_at_str
    return params_o
  end

  def join
    @item  = Sns::Schedule.find(params[:id])
    if @item.is_join?(Core.profile)
      user = @item.members.where(:user_id => Core.profile.id).first
      user.state = params[:do]
      user.save
    else
      user = Sns::Member.new
      user.state = params[:do]
      user.user_id = Core.profile.id
      @item.members << user
      user.save
    end
    proposal = Sns::FriendProposal.where({:fr_user_id=>@item.created_user_id, :to_user_id=>Core.profile.id,:schedule_id=>@item.id}).first
    unless proposal.blank?
      if params[:do]=="join"
        proposal.state = "recognized"
      else
        proposal.state = "refuzed"
      end
      proposal.save
    end
    return redirect_to sns_schedule_path(@project_code,@item)
  end


protected

  def validate_date
    @month = params[:month]
    @year  = params[:year]
    return false if !@month.blank? && @month !~ /^(0[1-9]|10|11|12)$/
    return false if !@year.blank? && @year !~ /^[1-9][0-9][0-9][0-9]$/
    @year  = @year.to_i
    @month = @month.to_i if @month
    params[:calendar_event_year]  = @year
    params[:calendar_event_month] = @month
    params[:calendar_event_min_date] = @min_date
    params[:calendar_event_max_date] = @max_date

    return true
  end

  def select_layout
    layout = "admin/sns/project"
    layout
  end
end
