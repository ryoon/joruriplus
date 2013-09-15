# encoding: utf-8
module Sns::CalendarsHelper

  def schedule_move(s_day,project_code,options={})
    if options[:day_link]
      days_hash = link_days(s_day)
    else
      days_hash = link_months(s_day)
    end
    separate = %Q(<span class="separate">|</span>)
    ret = ""
    days_hash.each do |d|
      if options[:day_link]
        link_date = daily_sns_schedules_path(project_code,{:st_date=>d[:st_date]})
      else
        link_date =  sns_schedules_path(project_code,{:year=>d[:year],:month=>d[:month]})
      end
      ret += %Q(#{link_to d[:label],link_date})
      ret += separate if d[:separate]==true
    end
    return ret
  end

  def side_schedule_move(date_str, project_code)
    s_day = Time.parse(date_str)
    days_hash = side_link_days(s_day)
    ret = %Q(<span class="last_month">←</span>)
    separate = %Q(<span class="separate">|</span>)
    days_hash.each do |d|
      ret += %Q(#{link_to d[:label], sns_schedules_path(project_code,{:year=>d[:year],:month=>d[:month]})})
      ret += separate if d[:separate]==true
    end
    ret += %Q(<span class="following_month">→</span>)
    return ret
  end

  def six_months(s_day)
    ret = [
      [s_day.months_ago(6),true],
      [s_day.months_ago(5),true],
      [s_day.months_ago(4),true],
      [s_day.months_ago(3),true],
      [s_day.months_ago(2),true],
      [s_day.months_ago(1),true],
      [s_day,true],
      [s_day.months_since(1),true],
      [s_day.months_since(2),true],
      [s_day.months_since(3),true],
      [s_day.months_since(4),true],
      [s_day.months_since(5),true],
      [s_day.months_since(6),false]
    ]
    return ret
  end

  def link_days(s_day)
    ret = []
    days = six_months(s_day)
    days.each do |m|
      if s_day.month == m[0].month
        ret << {:label=>"表示月", :st_date=>m[0].strftime("%Y%m%d"),:separate=>m[1]}
      elsif m[1]==false
        ret << {:label=>"#{m[0].month}月", :st_date=>m[0].strftime("%Y%m%d"),:separate=>m[1]}
      else
        ret << {:label=>"#{m[0].month}月", :st_date=>m[0].strftime("%Y%m%d"),:separate=>m[1]}
      end
    end
    return ret
  end

  def link_months(s_day)
    ret =[]
    months = six_months(s_day)
    months.each do |m|
      if s_day.month == m[0].month
        ret << {:label=>"表示月",:year=>m[0].year,:month=>fit_digit(m[0].month.to_s,2),:separate=>m[1]}
      elsif m[1]==false
        ret << {:label=>"#{m[0].month}月",:year=>m[0].year,:month=>fit_digit(m[0].month.to_s,2),:separate=>m[1]}
      else
        ret << {:label=>"#{m[0].month}月",:year=>m[0].year,:month=>fit_digit(m[0].month.to_s,2),:separate=>m[1]}
      end
    end
    return ret
  end

  def side_link_days(s_day)
    ret =[]
    ret << {:label=>"前の月",:year=>s_day.months_ago(1).year,:month=>fit_digit(s_day.months_ago(1).month.to_s,2),:separate=>true}
    ret << {:label=>"一覧へ",:year=>s_day.year,:month=>fit_digit(s_day.month.to_s,2),:separate=>true}
    ret << {:label=>"次の月",:year=>s_day.months_since(1).year,:month=>fit_digit(s_day.months_since(1).month.to_s,2),:separate=>false}
    return ret
  end



end
