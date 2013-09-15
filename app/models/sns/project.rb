# -*- encoding: utf-8 -*-
class Sns::Project
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia
  include Sns::Model::Base

  field :title
  field :caption
  field :code
  field :created_user_id
  field :sequence, :type=>Float
  field :publish
  field :state
  field :ldap, :type=>Integer
  field :contents, :type=>Array
  field :leave_kind
  field :project_file_limit, :type=>Integer
  field :post_file_limit, :type=>Integer
  field :reminder_show, :type=>Integer

  after_save :update_reminder_status

  validates_presence_of :title, :message=>"が、入力されていません。"
  validates_presence_of :caption, :message=>"が、入力されていません。"


  embeds_many :members, :class_name=>"Sns::Member"
  embeds_many :managers, :class_name=>"Sns::ProjectMember"
  referenced_in :created_user, :class_name=>"Sns::Profile"

  before_create :sequence_number

  after_create :set_code

  def update_reminder_status
    use_reminder = false
    begin
      rails_env = ENV['RAILS_ENV']
      config = YAML.load_file('config/core.yml')
      use_reminder = config[rails_env]['reminder']
    rescue
      return false
    end
    return false if use_reminder != true
    remind_state = "disabled"
    remind_state = "enabled" if self.reminder_show.to_i == 1
    Gw::PlusUpdate.update_all({:state=>remind_state},{:project_id=>self.id.to_s} ) rescue nil
    return true
  end


  def pending_members(p_member,p_manager)
    ret = []
    members_id = []
    if p_member == true
      pending_member = Sns::FriendProposal.where(:project_id=>self.id, :state.in=>["unread","read"], :kind=>"project")
      pending_member.each do |p|
        to_user = p.to_user
        if to_user
          next if self.is_join?(to_user)
          if members_id.index(to_user.id).blank?
            ret << to_user
            members_id << to_user.id
          end
        end
      end if pending_member
    end
    if p_manager == true
      pending_manager = Sns::FriendProposal.where(:project_id=>self.id, :state.in=>["unread","read"], :kind=>"project_manager")
      pending_manager.each do |p|
        to_user = p.to_user
        if to_user
          if p_member
            next if self.is_join?(to_user)
          else
            next if self.is_manager?(to_user)
          end
          if p_member == true
           ret << to_user if members_id.index(to_user.id).blank?
          else
            ret << to_user
          end
        end
      end if pending_manager
    end
    return ret
  end

  def set_code
    return unless self.code.blank?
    self.code = "project#{fit_digit(self.sequence.to_i, 3, '0')}"
    self.save({:validate=>false})
  end

  def members_select
    p_members = self.members
    select = []
    p_members.each do |m|
      p_user = m.user
      select << [p_user.name, p_user.id]
    end
    return select
  end

  def project_uri
    "/_admin/sns/projects/#{self.code}/reports"
  end

  def is_member_leave?(member_item, u_role)
    return false if u_role == true && member_item.user_id == Core.profile.id
    return true
  end

  def is_admin?(user=Core.user, profile=Core.profile)
    return true if user.has_auth?(:manager)
    m_cnt = self.managers.where(:user_id => profile.id)
    return true unless m_cnt.blank?
    return false
  end

  def is_join?(user=Core.profile)
    m_cnt = self.managers.where(:user_id => user.id)
    return true unless m_cnt.blank?
    cnt = self.members.where(:user_id => user.id)
    return true unless cnt.blank?
    return false
  end


  def is_penging?(user=Core.profile , kind="project")
    if kind=="project"
      return false if self.is_member?(user)
    else
      return false if self.is_manager?(user)
    end
    cnt = Sns::FriendProposal.where(:project_id=>self.id, :state.in=>["unread","read"], :kind=>kind, :to_user_id=>user.id)
    return false unless cnt.blank?
    return true
  end

  def is_member?(user=Core.profile)
    cnt = self.members.where(:user_id => user.id)
    return false if cnt.blank?
    return true
  end

  def is_manager?(user=Core.profile)
    m_cnt = self.managers.where(:user_id => user.id)
    return false if m_cnt.blank?
    return true
  end

  def delete_member(user)
    del_member = self.members.where(:user_id => user.id).count
    if del_member.destroy
      return true
    else
      return false
    end if del_member
    return false
  end

  def publich_select
    select = [["公開","public"],["非公開","closed"]]
    return select
  end
  def publish_show
    publich_select.each {|a| return a[0] if a[1] == publish }
    return nil
  end

  def state_select
    select = [["有効","enabled"],["無効","disabled"],["削除","deleted"]]
    return select
  end

  def state_show
    state_select.each {|a| return a[0] if a[1] == state }
    return nil
  end

  def leave_select
    select = [["退会時に申請が必要","proposal"],["退会時に申請が必要ない","self"]]
    return select
  end

  def leave_show
    leave_select.each {|a| return a[0] if a[1] == leave_kind }
    return nil
  end

  def reminder_config_select
    select = [["表示しない",0],["表示する",1]]
    return select
  end
  def reminder_config_show
    reminder_config_select.each {|a| return a[0] if a[1] == reminder_show.to_i }
    return nil
  end


  def project_file_limit_show
    return self.project_file_limit unless self.project_file_limit.blank?
    return 300
  end

 def post_file_limit_show
    return self.post_file_limit unless self.post_file_limit.blank?
    return 10
  end

  def file_size_limit
    project_limit = 300
    post_limit = 5
    project_limit = self.project_file_limit unless self.project_file_limit.blank?
    post_limit = self.post_file_limit unless self.post_file_limit.blank?
    file_size = file_size_sum
    if file_size >= ((project_limit * 1024 * 1024) - (post_limit * 1024 * 1024))
      return false
    else
      return true
    end
  end

  def file_size_sum
    photos_size = Sns::Photo.where(:file_size.exists=>true,:project_id=>self.id, :is_project=>1).sum(:file_size)
    files_size = Sns::File.where(:file_size.exists=>true,:project_id=>self.id, :is_project=>1).sum(:file_size)
    return 0 if files_size.blank? or photos_size.blank?
    total_size = photos_size + files_size
    if total_size.to_s =~ /^[0-9]+$|^[0-9]+\.0$/
      return total_size
    else
      return 0
    end
  end

  def file_size_show
    photos_size = Sns::Photo.where(:file_size.exists=>true,:file_size.ne=>"", :project_id=>self.id, :is_project=>1).sum(:file_size)
    files_size = Sns::File.where(:file_size.exists=>true,:file_size.ne=>"", :project_id=>self.id, :is_project=>1).sum(:file_size)
    files_size = 0 if files_size.blank?
    photos_size = 0 if photos_size.blank?
    total_size = photos_size + files_size
    return file_eng_unit(total_size)
  end

  def file_eng_unit(file_size)
    _size = file_size
    return '' unless _size.to_s =~ /^[0-9]+$|^[0-9]+\.0$/
    if _size >= 10**9
      _kilo = 3
      _unit = 'G'
    elsif _size >= 10**6
      _kilo = 2
      _unit = 'M'
    elsif _size >= 10**3
      _kilo = 1
      _unit = 'K'
    else
      _kilo = 0
      _unit = ''
    end

    if _kilo > 0
      _size = (_size.to_f / (1024**_kilo)).to_s + '000'
      _keta = _size.index('.')
      if _keta == 3
        _size = _size.slice(0, 3)
      else
        _size = _size.to_f * (10**(3-_keta))
        _size = _size.to_f.ceil.to_f / (10**(3-_keta))
      end
    end

    "#{_size}#{_unit}Bytes"
  end

  def save_with_rels(params, mode, options={})
    users = params[:user_id]
    if users.blank?
      self.errors.add_to_base "メンバーが登録されていません。"
    end
    project = Sns::Project.find(:first, :conditions=>{:_id=>params[:project_id]})
    if project.blank?
      self.errors.add_to_base "プロジェクトのデータが正しくありません。"
    end
    if self.errors.size > 0
      return false
    else
      #adds 差分更新
      old_users = project.members
      old_users.each_with_index{|old_user, x|
        use = 0
        users.each_with_index{|user, y|
          if old_user.user_id.to_s == user.to_s
            users.delete_at(y)
            use = 1
          end
        }
        old_user.destroy if use == 0
      }
      users.each_with_index{|user, y|
        new_user = Sns::Member.new({:user_id=>user, :state=>"disabled"})
        project.members << new_user
      }
      add_user_post(project.members) if mode==:create
      return true
    end
  end

  def add_user_post(project_members)
    member_list = []
    project_members.each do |pm|
      member_list << pm.user_id if pm.user_id != Core.profile.id
    end
    attribute = {
            :text =>%Q(#{Core.profile.name}さんが<a href="#{project_uri}">「#{self.title}」</a>にあなたを追加しました。),
            :kind =>["project_member"],
            :content_id=>member_list,
            :privacy =>"notice",
            :created_user_id=>Core.profile.id,
            :project_id=>self.id,
            :is_project=>1
          }
    Sns::Post.create(attribute)
  end

  def auth_check(user=Core.user,profile=Core.profile)
    return true if user.has_auth?(:manager)
    return false if self.publish=="closed" && !self.is_join?(profile)
    return true
  end

  class << self
    def word(word)
      if word.blank?
        criteria.all
      else
        search_words = word.to_s.split(/[ 　]+/)
        target = []
        search_words.each do |m|
          str = m.gsub(/\./,'\.')
          target << /.*#{str}.*/
        end
        criteria.any_of({:title.all=>target},{:caption.all=>target},{:code.all=>target})
      end
    end

    def user_word(word)
      if word.blank?
        criteria.any_of({"members.user_id" => Core.profile.id}, {:publish=>"public"})
      else
        search_words = word.to_s.split(/[ 　]+/)
        target = []
        search_words.each do |m|
          str = m.gsub(/\./,'\.')
          target << /.*#{str}.*/
        end
        query_h = [
        {:title.all=>target,"members.user_id" => Core.profile.id},
        {:caption.all=>target,"members.user_id" => Core.profile.id},
        {:code.all=>target,"members.user_id" => Core.profile.id},
        {:title.all=>target,:publish=>"public"},
        {:caption.all=>target,:publish=>"public"},
        {:code.all=>target,:publish=>"public"},
        ]
        criteria.any_of(query_h)
      end
    end
    def title(str)
      criteria.where(:title => /.*#{str}.*/)
    end
    def caption(str)
      criteria.where(:caption => /.*#{str}.*/)
    end
  end
end
