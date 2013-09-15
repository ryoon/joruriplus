# encoding: utf-8
module FormHelper

  ## tinyMCE
  def init_tiny_mce(options = {})
    settings = []
    options.each do |k, v|
      v = %Q("#{v}") if v.class == String
      settings << "#{k}:#{v}"
    end
    [
      javascript_include_tag("/_common/js/tiny_mce/tiny_mce.js"),
      javascript_include_tag("/_common/js/tiny_mce/init.js"),
      javascript_tag("initTinyMCE({#{settings.join(',')}});")
    ].join("\n")
  end

  def submission_label(name)
    {
      :add       => '追加する',
      :create    => '作成する',
      :register  => '登録する',
      :edit      => '編集する',
      :update    => '更新する',
      :change    => '変更する',
      :delete    => '削除する'
    }[name]
  end

  def submit(*args)
    make_tag = Proc.new do |_name, _label|
      _label ||= submission_label(_name) || _name.to_s.humanize
      submit_tag(_label, :name => "commit_#{_name}", :class => _name)
    end

    h = '<div class="submitters">'
    if args[0].class == String || args[0].class == Symbol
      h += make_tag.call(args[0], args[1])
    elsif args[0].class == Hash
      args[0].each {|k, v| h += make_tag.call(k, v) }
    elsif args[0].class == Array
      args[0].each {|v, k| h += make_tag.call(k, v) }
    end
    h += '</div>'
  end

  def limit_params
    ret = [["10",10],["20",20],["30",30],["50",50],["100",100],["300",300],["500",500]]
    return ret
  end

  def form_publish_select(options={})
    range_list =  [["限定公開（友達）","friend"]] #,[Core.user_group.name,"group"] 所属は一時保留
    range_list << ["非公開","closed"] if options[:is_note]
    c_groups = Sns::CustomGroup.find(:all, :conditions=>{:user_id=>Core.profile.id})
    unless c_groups.blank?
      c_groups.each do |c|
        range_list << ["└カスタム（#{c.name}）", c.sequence]
      end
    end
    range_list << ["限定公開（ワンタイム）","select"]
    range_list << ["--------------","none"]
    range_list << ["所属通知","group"]
    range_list << ["--------------","none"]
    range_list << ["全庁通知","all"]
    range_list << ["--------------","none"]
    range_list << ["公開（その他フィード）","public"]
    return range_list
  end

  def publish_select_show(id="tweet_privacy", name="tweet[privacy]",options={})
    range_list = form_publish_select(options)
    ret = "<select id='#{id}'' name='#{name}'>"
    range_list.each do |x|
       selected = ""
      if options[:pr_id] =~ /^[0-9]*$/
        selected = " selected" if options[:pr_id].to_i == x[1].to_i
      elsif options[:pr_id]==x[1]
        selected = " selected"
      end
      ret += "<option value='#{x[1]}'#{selected}>#{x[0]}</option>"
    end
    ret += "</select>"
    return ret.html_safe
  end

  def display_state_select
    select = [["表示する","enabled"],["表示しない","disabled"]]
    return select
  end

  def notice_state_select
    select = [["通知する","on"],["通知しない","off"]]
    return select
  end

end