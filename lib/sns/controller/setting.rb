# coding: utf-8
module Sns::Controller::Setting

  def display_items_config(manager=false)
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
      :proposal=>"off",
      :recognized=>"off",
      :invite=>"off",
      :invite_recog=>"off",
      :project=>"off",
      :leave=>"on",
      :leave_recog=>"on",
      :leave_refuse=>"on"
      }
    end
    if manager
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
      setting[:ind_addr]="enabled"
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

  def is_enabled(edit_current,manager=false)
    return true if edit_current == "closed" || edit_current == "public"
    config = display_items_config(manager)
    ret = true
    if edit_current == "addr"
     if config[:addr]=="disabled"
       ret = false
     else
       ret = false if is_addresses_closed(config)
     end
    elsif edit_current == "skill"
     if config[:skill]=="disabled"
       ret = false
     else
       ret = false if config[:job_skill]=="disabled" && config[:license]=="disabled" && config[:circle]=="disabled"
     end
    elsif edit_current == "interest"
     if config[:interest]=="disabled"
       ret = false
     else
       ret = false if config[:interest_main]=="disabled" && config[:thought]=="disabled" && config[:research_group]=="disabled"
     end
    elsif edit_current == "pr"
     if config[:pr]=="disabled"
       ret = false
     else
       ret = false if config[:self_introduce]=="disabled" && config[:resolution]=="disabled" && config[:program]=="disabled"
     end
    elsif edit_current == "office"
     if config[:history]=="disabled"
       ret = false
     else
       ret = false if config[:office_name]=="disabled" && config[:offitial_position]=="disabled" && config[:assigned_job]=="disabled" && config[:office_remarks]=="disabled"&& config[:extension]=="disabled"
     end
   else
     if config[:base_info]=="disabled"
       ret = false
     else
       ret = false if config[:sex]=="disabled" && config[:bloodtype]=="disabled" && config[:birthday]=="disabled"
     end
   end
    return ret
  end

  def is_addresses_closed(config)
    ret = true
    attr = [:address_main, :phone_number, :mobile_number,:mail_addr, :ind_addr,:facebook_name,:addr_01]
    attr.each do |a|
      ret = false if config[a]=="enabled"
    end
    return ret
  end

end
