# encoding: utf-8
module Sns::Model::Post

  def remove_html_tag(str)
    return nil if str.blank?
    str.gsub(/</, "&lt;")
    str.gsub(/>/, "&gt;")
    return str
  end

  def uri_to_link(ret)
    return nil if ret.blank?
    uri_reg = URI.regexp(%w[http https])
    ret = ret.gsub!(uri_reg) {%Q{<a href="#{$&}" target="_blank">#{$&}</a>}} if ret =~ uri_reg
    return ret
  end

  def mailaddr_to_link(ret)
    return nil if ret.blank?
    mail_reg = /[a-zA-Z0-9_\.\-]+@[A-Za-z0-9_\.\-]+\.[A-Za-z0-9_\.\-]+/
    ret = ret.gsub!(mail_reg) {%Q{<a href="mailto:#{$&}">#{$&}</a>}}  if ret =~ mail_reg
    return ret
  end


  def post_to_doc_link(str,post_doc_uri, length=30)
    original_body = str
    line_str = []
    str.each_line {|line|
      line_str << line
    }
    if line_str.length > 3
      str = "#{line_str[0]}#{line_str[1]}#{line_str[2]}"
    end
    unless str.blank?
      str = remove_html_tag(str)
      str = str.slice(0,length)
      str = str.strip
      str = str.gsub(/\r\n|\r|\n/, '<br />')
    end
    str = uri_to_link(str)
    str = mailaddr_to_link(str)
    if line_str.blank?
      str += "…<br /><a href='#{post_doc_uri}' target='_blank'>続きはこちら>></a>" if original_body.length > length
    else
      if line_str.length > 3
        str += "…<br /><a href='#{post_doc_uri}' target='_blank'>続きはこちら>></a>" if line_str.length > 3
      else
        str += "…<br /><a href='#{post_doc_uri}' target='_blank'>続きはこちら>></a>" if original_body.length > length
      end
    end
    return str
  end

end
