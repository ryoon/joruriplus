# encoding: utf-8
class Sys::Lib::Mail::Base < ActionMailer::Base
  def default(mail_fr, mail_to, subject, message)
    from       mail_fr
    recipients mail_to
    subject    subject
    body       message
  end
end