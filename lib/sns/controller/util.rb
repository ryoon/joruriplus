# coding: utf-8
module Sns::Controller::Util

  def datetime_str(d, value_if_err='!!!')
    begin
      return d.strftime("%Y-%m-%d %H:%M")
    rescue
      #pp 'can\'t convert d(date_common)'
      return (value_if_err == '!!!' ? d.to_s : value_if_err.to_s )
    end
  end

  def string_to_date(s=nil, options={})
    default = options[:default]
    default = Date.today if default.nil?
    return default if s.nil?
    ret = s =~ /[0-9]{8}/ ? Date.strptime(s, '%Y%m%d') : default
    return options[:to_s].nil? ? ret : datetime_str(ret)
  end

  def string_to_datetime(s=nil, options={})
    default = options[:default]
    default = DateTime.now if default.nil?
    return default if s.nil?
    ret = DateTime.parse(s)
    return options[:to_s].nil? ? ret : datetime_str(ret)
  end


  def string_to_time(s=nil, options={})
    default = options[:default]
    default = DateTime.now if default.nil?
    return default if s.nil?
    ret = Time.parse(s)
    return options[:to_s].nil? ? ret : datetime_str(ret)
  end
end
