# coding: utf-8
module Sys::Controller::Service::Base

  def self.included(mod)
    mod.protect_from_forgery :except => [:receive]
  end

  # front
  def receive
    respond_content = default_content

    # check params
    return render(:xml => ng_content('wrong params!')) unless is_valid_params
    # auth
    @user = authenticate(params[:account], params[:password])
    return render(:xml => ng_content('unknown account!')) unless @user

    # do action
    begin
      status, content = send(params[:do], @user)
      respond_content = set_content status, content
    rescue => e
      return render(:xml => ng_content(e))
    end
    render(:xml => respond_content)
  end


protected

  def is_valid_params
    !params[:account].blank? && !params[:password].blank? && !params[:do].blank?
  end

  def authenticate(_account, _password)
    # must include Sys::Controller::Admin::Auth
    if logged_in?
      user = current_user
      unless _account.to_s == user.account.to_s
        return false unless new_login(_account, _password)
      end
    else
      return false unless new_login(_account, _password)
    end
    return current_user
  end

  def default_content
    #"<?xml version=\"1.0\" encoding=\"UTF-8\"?><result><status>OK</status><result>"
    set_content
  end

  def ng_content(content='')
    #"<?xml version=\"1.0\" encoding=\"UTF-8\"?><result><status>NG</status></result>"
    set_content "NG", content
  end

  def set_content(status="OK", content='')
      xml = Builder::XmlMarkup.new :indent => 2
      xml.instruct!
      result_xml = xml.result {
        xml.status  status
        xml.content do |c|
          xml << content
        end
      }
      result_xml
  end

end
