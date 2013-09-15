# coding: utf-8
class Gw::Admin::SiteinfoController < Sys::Controller::Admin::Base
  layout "admin/sns/sns"

  def index
    rails_env = ENV['RAILS_ENV']
    @user_reminder = "使用しない"
    begin
      site = YAML.load_file('config/core.yml')
      @host = site[rails_env]['host']
      #リマインダー連携
      reminder = site[rails_env]['reminder']
      if reminder==true
        @user_reminder = "使用する"
      end
    rescue
    end
    #クライアントIPアドレス
    if http_client_ip = request.env['HTTP_CLIENT_IP']
      @remote_ip = http_client_ip
    elsif x_forward_for = request.env['HTTP_X_FORWARD_FOR']
      @remote_ip = x_forward_for.split(',').last.strip
    else
      @remote_ip = request.remote_ip
    end
  end

end