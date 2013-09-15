# encoding: utf-8
class Sns::Management
  include Mongoid::Document
  include Mongoid::Timestamps

  field :post
  field :file
  field :proposal
  field :recognized
  field :invite
  field :invite_recog
  field :project
  field :leave
  field :leave_recog
  field :leave_refuse
  field :join
  field :join_recog
  field :help_link_1
  field :help_link_2
  field :help_link_3
  field :help_link_4

  #プロフィール大項目
  field :base_info
  field :history
  field :address
  field :skill
  field :interest
  field :pr

  #プロフィール小項目
  field :sex
  field :bloodtype
  field :birthday

  field :address_main
  field :phone_number
  field :mobile_number
  field :mail_addr
  field :ind_addr
  field :facebook_name
  field :addr_01

  field :job_skill
  field :license
  field :circle

  field :interest_main
  field :thought
  field :research_group

  field :self_introduce
  field :resolution
  field :program

  #勤務先
  field :office_name
  field :offitial_position
  field :assigned_job
  field :office_remarks
  field :extension

  #プロジェクトファイル容量
  field :project_file_limit, :type=>Integer
  field :project_post_limit, :type=>Integer

  def get_help_uri(help_no)
    ret = case help_no
    when 1
      self.help_link_1
    when 2
      self.help_link_2
    when 3
      self.help_link_3
    when 4
      self.help_link_4
    else
      ""
    end
    return ret
  end


  def self.global_setting(edit=false)
    setting = Sns::Management.first
    if setting.blank?
      setting = {
      :post => "enabled",
      :file=>"enabled",
      :base_info=>"enabled",
      :history=>"enabled",
      :address=>"enabled",
      :skill=>"enabled",
      :interest=>"enabled",
      :pr=>"enabled",
      :sex=>"enabled",
      :bloodtype=>"enabled",
      :birthday=>"enabled",
      :address_main=>"enabled",
      :phone_number=>"enabled",
      :mobile_number=>"enabled",
      :mail_addr=>"enabled",
      :ind_addr=>"enabled",
      :facebook_name=>"enabled",
      :addr_01=>"enabled",
      :job_skill=>"enabled",
      :license=>"enabled",
      :circle=>"enabled",
      :interest_main=>"enabled",
      :thought=>"enabled",
      :research_group=>"enabled",
      :self_introduce=>"enabled",
      :resolution=>"enabled",
      :program=>"enabled",
      :office_name=>"enabled",
      :offitial_position=>"enabled",
      :assigned_job=>"enabled",
      :office_remarks=>"enabled",
      :extension=>"enabled",
      :proposal=>"off",
      :recognized=>"off",
      :invite=>"off",
      :invite_recog=>"off",
      :project=>"off",
      :leave=>"on",
      :leave_recog=>"on",
      :leave_refuse=>"on",
      :join=>"on",
      :join_recog=>"on"
      }
    end
    if Core.user.has_auth?(:manager) && edit==false
      setting[:post]="enabled"
      setting[:file]="enabled"
      setting[:base_info]="enabled"
      setting[:history]="enabled"
      setting[:address]="enabled"
      setting[:skill]="enabled"
      setting[:interest]="enabled"
      setting[:pr]="enabled"

      setting[:sex]="enabled"
      setting[:bloodtype]="enabled"
      setting[:birthday]="enabled"

      setting[:address_main]="enabled"
      setting[:phone_number]="enabled"
      setting[:mobile_number]="enabled"
      setting[:mail_addr]="enabled"
      setting[:facebook_name]="enabled"
      setting[:addr_01]="enabled"

      setting[:job_skill]="enabled"
      setting[:license]="enabled"
      setting[:circle]="enabled"

      setting[:interest_main]="enabled"
      setting[:thought]="enabled"
      setting[:research_group]="enabled"

      setting[:self_introduce]="enabled"
      setting[:resolution]="enabled"
      setting[:program]="enabled"

      setting[:office_name]="enabled"
      setting[:offitial_position]="enabled"
      setting[:assigned_job]="enabled"
      setting[:office_remarks]="enabled"
      setting[:extension]="enabled"
    end
    return setting
  end

end
