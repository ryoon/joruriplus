# encoding: utf-8
module Sys::Lib::Mail::Address

  def system_mail_addr
    smtp_setting = {}
    begin
      smtp_setting = ActionMailer::Base.smtp_settings
    rescue
      smtp_setting = {:address => "127.0.0.0"}
    end
    mail_addr = "#{Core.title} <joruri-plus@#{smtp_setting[:address]}>"
  end

end
