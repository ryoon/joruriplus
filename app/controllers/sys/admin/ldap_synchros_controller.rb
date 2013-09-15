# encoding: utf-8
class Sys::Admin::LdapSynchrosController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)
  end

  def index
    item = Sys::LdapSynchro.new#.readable
    item.page  params[:page], params[:limit]
    item.order params[:sort], 'version DESC'
    @items = item.find(:all, :group => :version)
    _index @items
  end

  def show
    @version = params[:id]

    item = Sys::LdapSynchro.new
    item.and :version, @version
    item.and :parent_id, 0
    item.and :entry_type, 'group'
    @items = item.find(:all, :order => 'sort_no, code')

    _show @items
  end

  def new
    @item = Sys::LdapSynchro.new({})
  end

  def create
    @version = Time.now.strftime('%s')
    @results = {:group => 0, :user => 0, :error => 0}
    error   = nil
    @sort_no = 10
    begin
      create_synchros
    #rescue ActiveLdap::LdapError::AdminlimitExceeded
    #  error = "LDAP通信時間超過"
    rescue => e
      error = e
    end

    if error.nil?
      messages = ["中間データを作成しました。"]
      messages << "-- グループ #{@results[:group]}件"
      messages << "-- ユーザ #{@results[:user]}件"
      messages << "-- エラー #{@results[:error]}件" if @results[:error] > 0
      flash[:notice] = messages.join('<br />').html_safe
      redirect_to url_for(:action => :show, :id => @version)
    else
      flash[:notice] = "中間データの作成に失敗しました。［ #{error} ］"
      redirect_to url_for(:action => :index)
    end
  end

  def update

  end

  def destroy
    Sys::LdapSynchro.delete_all(['version = ?', params[:id]])
    flash[:notice] = "削除処理が完了しました。"
    redirect_to url_for(:action => :index)
  end

  def synchronize
    @version = params[:id]

    item = Sys::LdapSynchro.new
    item.and :version, @version
    item.and :parent_id, 0
    item.and :entry_type, 'group'
    @items = item.find(:all, :order => 'sort_no, code')

    unless parent = Sys::Group.find_by_parent_id(0)
      return render :inline => "グループのRootが見つかりません。", :layout => true
    end

    Sys::Group.update_all("ldap_version = NULL")
    Sys::User.update_all("ldap_version = NULL")

    @results = {:group => 0, :gerr => 0, :user => 0, :uerr => 0, :project => 0, :perr => 0}
    @items.each {|group| do_synchro(group, parent)}

    @results[:udel] = Sys::User.destroy_all("ldap = 1 AND ldap_version IS NULL").size
    @results[:gdel] = Sys::Group.destroy_all("parent_id != 0 AND ldap = 1 AND ldap_version IS NULL").size

    #プロジェクト作成処理
    #update_projects
    #@results[:pdel] = Sns::Project.where(:state=>"deleted", :ldap=>1).count
    messages = ["同期処理が完了しました。<br />"]
    messages << "グループ"
    messages << "-- 更新 #{@results[:group]}件"
    messages << "-- 削除 #{@results[:gdel]}件" if @results[:gdel] > 0
    messages << "-- 失敗 #{@results[:gerr]}件" if @results[:gerr] > 0
    messages << "ユーザ"
    messages << "-- 更新 #{@results[:user]}件"
    messages << "-- 削除 #{@results[:udel]}件" if @results[:udel] > 0
    messages << "-- 失敗 #{@results[:uerr]}件" if @results[:uerr] > 0
    #messages << "プロジェクト作成"
    #messages << "-- 更新 #{@results[:project]}件"
    #messages << "-- 削除 #{@results[:pdel]}件" if @results[:pdel] > 0
    #messages << "-- 失敗 #{@results[:perr]}件" if @results[:perr] > 0

    flash[:notice] = messages.join('<br />').html_safe

    redirect_to(:action => :index)
  end

protected
  def do_synchro(group, parent = nil)
    ## group
    sg                = Sys::Group.find_by_code(group.code) || Sys::Group.new
    sg.code           = group.code
    sg.parent_id      = parent.id
    sg.state        ||= 'enabled'
    sg.web_state    ||= 'public'
    sg.name           = group.name
    sg.name_en        = group.name_en if !group.name_en.blank?
    sg.email          = group.email if !group.email.blank?
    sg.level_no       = parent.level_no + 1
    sg.sort_no        = group.sort_no
    sg.ldap         ||= 1
    sg.ldap_version   = @version
    sg.group_s_name  = group.group_s_name
    if sg.ldap == 1
      if sg.save(:validate => false)
        @results[:group] += 1
      else
        @results[:gerr] += 1
        return false
      end
    end

    ## users
    if group.users.size > 0
      group.users.each do |user|
        su                = Sys::User.find_by_account(user.code) || Sys::User.new
        su.account        = user.code
        su.state        ||= 'enabled'
        su.auth_no      ||= 2
        su.name           = user.name
        su.name_en        = user.name_en
        su.email          = user.email
        su.kana           = user.kana
        su.ldap         ||= 1
        su.ldap_version   = @version
        su.sort_no        = user.sort_no
        su.in_group_id    = sg.id
        office_params = {
          :name=>sg.name,
          :offitial_position => user.title,
          :assigned_job => user.employee_type
        }
        if su.ldap == 1
          if su.save
            update_profile(su, office_params)
            @results[:user] += 1
          else
            @results[:uerr] += 1
          end
        end
      end
    end

    ## next
    if group.children.size > 0
      group.children.each {|g| do_synchro(g, sg)}
    end
  end

  def update_profile(user,office_params)
    n_prof           = Sns::Profile.find(:first, :conditions=>{:account=>user.account}) || Sns::Profile.new
    n_prof.account   = user.account
    n_prof.user_id   = user.id
    n_prof.name      = user.name
    n_prof.mail_addr = user.email
    n_prof.kana      = user.kana
    n_prof.sort_no   = user.sort_no
    n_prof.save(:validate => false)

    n_office = n_prof.office
    if n_office.blank?
      n_prof.office = Sns::Office.new(office_params)
      n_prof.save
    else
      n_office.update_attributes(office_params)
      n_office.save
    end
    #set_members_sort_no(n_prof)
  end

  def set_members_sort_no(prof)
    p_members = Sns::Project.where("members.user_id"=>prof.id)
    p_members.each do |p|
      member = p.members.where({:user_id=>prof.id}).first
      if member
        member.sort_no = prof.sort_no
        member.save
      end
      manager = p.managers.where({:user_id=>prof.id}).first
      if manager
        manager.sort_no = prof.sort_no
        manager.save
      end
    end
  end

  def update_projects
    group_project = Sns::Project.find(:all, :conditions=>{:ldap=>1})
    group_project.each do |ug|
      ug.update_attributes(:state=>"deleted")
    end
    groups = Sys::Group.find(:all, :conditions=>["ldap = ?", 1], :order=>:sort_no)
    groups.each do |g|
      project = Sns::Project.find(:first, :conditions=>{:code=>g.code}) || Sns::Project.new
      project.code = g.code
      project.publish = "closed"
      project.ldap = 1
      project.title = "#{g.name}プロジェクト"
      project.state = "enabled"
      project.caption ||= "#{g.name}のプロジェクトです。"
      project.leave_kind  = "ldap"
      if project.save
      users = g.users
        old_users = project.members
        unless old_users.blank?
          old_users.each_with_index{|old_user, x|
            use = 0
            users.each_with_index{|user, y|
              user_prof = Sns::Profile.where(:account=>user.account).first
              next if user_prof.blank?
              if old_user.user_id == user_prof.id
                users.delete_at(y)
                use = 1
              end
            }
            #old_user.destroy if use == 0
          }
        end
        users.each_with_index{|user, y|
          user_prof = Sns::Profile.where(:account=>user.account).first
          next if user_prof.blank?
          new_user = Sns::Member.new({:user_id=>user_prof.id, :state=>"enabled",:sort_no=>user_prof.sort_no})
          project.members << new_user
        }
        project_manager = project.managers.find(:all)
        if project_manager.blank?
          manager_user = Sns::Profile.where(:account=>%Q(#{project.code}0)).first
          unless manager_user.blank?
            p_manager = Sns::ProjectMember.new({:user_id=>manager_user.id, :state=>"enabled",:sort_no=>manager.sort_no})
            project.managers << p_manager unless project.is_manager?(manager_user)
          end
        else
          project_manager.each do |m|
          manager_user = m.user
            if manager_user.blank?
              m.destroy
            else
              if manager_user.account.slice(0,6) != project.code
                m.destroy
                new_manager_user = Sns::Profile.where(:account=>%Q(#{project.code}0)).fisrt
                p_manager = Sns::ProjectMember.new({:user_id=>new_manager_user.id, :state=>"enabled",:sort_no=>new_manager_user.sort_no})
                project.managers << p_manager unless project.is_manager?(new_manager_user)
              end
            end
          end
        end
        @results[:project] += 1
      else
        @results[:perr] += 1
      end
    end
  end

  def create_synchros(entry = nil, group_id = nil)
    if entry.nil?
      Core.ldap.group.children.each do |e|
        create_synchros(e, 0)
      end
      return true
    end

    #sort_no = 0
    #next_sort_no = Proc.new do
    #  sort_no += 10
    #end
    group = Sys::LdapSynchro.new({
      :parent_id    => group_id,
      :version      => @version,
      :entry_type   => 'group',
      :code         => entry.code,
      :name         => entry.name,
      :name_en      => entry.name_en,
      :email        => entry.email,
      :group_s_name => entry.group_s_name,
      #:sort_no      => entry.sort_no
      :sort_no      => @sort_no
    })
    unless group.save
      @results[:error] += 1
      return false
    end
    @results[:group] += 1
    @sort_no += 10

    entry.users.each do |e|
      user_sort_no = e.sort_no
      user_sort_no = "no_number" if e.sort_no.blank?
      user = Sys::LdapSynchro.new({
        :parent_id      => group.id,
        :version        => @version,
        :entry_type     => 'user',
        :code           => e.uid,
        :name           => e.name,
        :name_en        => e.name_en,
        :email          => e.email,
        :kana           => e.kana,
        :title          => e.title,
        :employee_type  => e.employee_type,
        :sort_no        => user_sort_no
      })
      user.save ? @results[:user] += 1 : @results[:error] += 1
    end

    entry.children.each do |e|
      create_synchros(e, group.id)
    end
  end


end
