# encoding: utf-8
module Sns::SettingsHelper

  def display_items_config(edit=false)
    return Sns::Management.global_setting(edit)
  end

  def is_menu_enabled(edit_current)
    config = display_items_config
    ret = true
    if edit_current == "addr"
     if config[:addr]=="disabled"
       ret = false
     else
       ret = false if is_addresses_closed(config)
     end
    elsif edit_current == "skill"
     if display_items_config[:skill]=="disabled"
       ret = false
     else
       ret = false if config[:job_skill]=="disabled" && config[:license]=="disabled" && config[:circle]=="disabled"
     end
    elsif edit_current == "interest"
     if display_items_config[:interest]=="disabled"
       ret = false
     else
       ret = false if config[:interest_main]=="disabled" && config[:thought]=="disabled" && config[:research_group]=="disabled"
     end
    elsif edit_current == "pr"
     if display_items_config[:pr]=="disabled"
       ret = false
     else
       ret = false if config[:self_introduce]=="disabled" && config[:resolution]=="disabled" && config[:program]=="disabled"
     end
    elsif edit_current == "office"
     if display_items_config[:history]=="disabled"
       ret = false
     else
       ret = false if config[:office_name]=="disabled" && config[:offitial_position]=="disabled" && config[:assigned_job]=="disabled" && config[:office_remarks]=="disabled" && config[:extension]=="disabled"
     end
    else
     if display_items_config[:base_info]=="disabled"
       ret = false
     else
       ret = false if config[:sex]=="disabled" && config[:bloodtype]=="disabled" && config[:birthday]=="disabled"
     end
    end
    return ret
  end

  def is_addresses_closed(config)
    ret = true
    #attr = [:address_main, :phone_number, :mobile_number,:mail_addr, :ind_addr,:facebook_name,:addr_01,:addr_02,:addr_03,
    #  :addr_04, :addr_05, :addr_06,:addr_07, :addr_08, :addr_09 ,:addr_10]
    attr = [:address_main, :phone_number, :mobile_number,:mail_addr, :ind_addr,:facebook_name,:addr_01]
    attr.each do |a|
      ret = false if config[a]=="enabled"
    end
    return ret
  end

  def post_limit
    post_limit = 5
    setting = Sns::Management.first
    unless setting.blank?
      post_limit = setting.project_post_limit
    end
    return post_limit
  end

  def notice_show(state)
    return "通知しない" if state=="off"
    return "通知する"
  end

  def help_link(help_no=1)
    setting = Sns::Management.first
    ret = ""
    return "" if setting.blank?
    help_url = setting.get_help_uri(help_no)
    unless help_url.blank?
      url = "/_admin/sso?to=gw&path=#{help_url}"
      ret = %Q(<span class="help">)
      ret += link_to("#", url, :target=>"_blank", :class=>"help")
      ret += %Q(</span>)
    end
    return ret.html_safe
  end

  def comment_limit
    return 100
  end
  def comment_limit_message
    #return "コメント件数が#{comment_limit}に達しているため、これ以上コメントできません。"
    return "コメント数制限に達しています"
  end

  def photo_limit
    #return 30
    return 5
  end

  def post_update_limit
    return Core.profile.post_update_limit
  end

  def update_limit_select
    limit_selects = [
      [5,5],
      [10,10],
      [15,15],
      [20,20],
      [30,30]
    ]
    return limit_selects
  end

  def activity_select_list
    Core.profile.notice_select
  end
  def enable_reminder
    use_reminder = false
    begin
      rails_env = ENV['RAILS_ENV']
      config = YAML.load_file('config/core.yml')
      use_reminder = config[rails_env]['reminder']
    rescue
      return false
    end
    return use_reminder
  end

end
