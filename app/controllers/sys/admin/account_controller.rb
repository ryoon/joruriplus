# encoding: utf-8
class Sys::Admin::AccountController < Sys::Controller::Admin::Base
  protect_from_forgery :except => [:login]

  def login
    skip_layout
    admin_uri = '/_admin'


    @uri = params[:uri] || cookies[:sys_login_referrer] || admin_uri
    @uri = @uri.gsub(/^http:\/\/[^\/]+/, '')
    return unless request.post?

    if request.mobile?
      login_ok = new_login_mobile(params[:account], params[:password], params[:mobile_password])
    else
      login_ok = new_login(params[:account], params[:password])
    end

    unless login_ok
      flash.now[:notice] = "ユーザＩＤ・パスワードを正しく入力してください"
      respond_to do |format|
        format.html { render }
        format.xml  { render(:xml => '<errors />') }
      end
      return true
    end

    if params[:remember_me] == "1"
      self.current_user.remember_me
      cookies[:auth_token] = {
        :value   => self.current_user.remember_token,
        :expires => self.current_user.remember_token_expires_at
      }
    end

    cookies.delete :sys_login_referrer
    Sys::Session.delete_past_sessions_at_random

    respond_to do |format|
      format.html { redirect_to @uri }
      format.xml  { render(:xml => current_user.to_xml) }
    end
  end

  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    redirect_to('action' => 'login')
  end

  def info
    skip_layout

    respond_to do |format|
      format.html { render }
      format.xml  { render :xml => Core.user.to_xml(:root => 'item', :include => :groups) }
    end
  end

  def sso
    skip_layout

    params[:to] ||= 'gw'
    #config = sso_setting(params[:to].to_sym)
    #raise 'SSOの設定がありません。' unless config = Joruri.config.sso_settings[params[:to].to_sym]
    unless config = Joruri.config.sso_settings[params[:to].to_sym]
      return redirect_to params[:path]
    end
    return redirect_to "/_admin" if config.blank?
    require 'net/http'
    Net::HTTP.version_1_2
    http = Net::HTTP.new(config[:host], config[:port])
    if config[:usessl]
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    http.start do |agent|
      parameters = "account=#{Core.user.account}&password=#{CGI.escape(Core.user.password.to_s)}&mobile_password=#{CGI.escape(Core.user.mobile_password.to_s)}"
      response = agent.post("/#{config[:path]}", parameters)
      token = response.body =~ /^OK/i ? response.body.gsub(/^OK /i, '') : nil

      uri = "#{config[:usessl] ? "https" : "http"}://#{config[:host]}:#{config[:port]}/"
      if token
        uri << "#{config[:path]}?account=#{Core.user.account}&token=#{token}"
        uri << "&path=#{CGI.escape(params[:path])}" if params[:path]
      end
      redirect_to uri
    end
  end


end
