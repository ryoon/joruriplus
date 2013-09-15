# encoding: utf-8
module LinkHelper
  def action_menu(type, link = nil, options = {})
    action = params[:action]

    if action =~ /index/
      return '' if [:index, :show, :edit, :destroy].index(type)
    elsif action =~ /(show|destroy)/
      return '' unless [:index, :edit, :destroy].index(type)
    elsif action =~ /(new|create)/
      return '' unless [:index].index(type)
    elsif action =~ /(edit|update)/
      return '' unless [:index, :show].index(type)
    end

    if type == :destroy
      options[:confirm] = '削除してよろしいですか？'
      options[:method]  = :delete
      #options[:remote]  = true
    end

    if link.class == String
      return link_to(type, link, options)
    elsif link.class == Array
      return link_to(link[0], link[1], options)
    else
      return link_to(type, url_for(:action => type), options)
    end
  end

  def link_to(*params)
    labels = {
      :up        => '上へ',
      :index     => '一覧',
      :list      => '一覧',
      :show      => '詳細',
      :new       => '新規作成',
      :edit      => '編集',
      :delete    => '削除',
      :destroy   => '削除',
      :open      => '公開',
      :close     => '非公開',
      :enabale   => '有効化',
      :disable   => '無効化',
      :recognize => '承認',
      :publish   => '公開',
      :close     => '非公開'
    }
    params[0] = labels[params[0]] if labels.key?(params[0])

    options = params[2]

    if options && options[:method] == :delete
      options[:method] = nil

      onclick = "var f = document.createElement('form');" \
        "f.style.display = 'none';" \
        "this.parentNode.appendChild(f);" \
        "f.method = 'POST';" \
        "f.action = this.href;" \
        "var m = document.createElement('input');" \
        "m.setAttribute('type', 'hidden');" \
        "m.setAttribute('name', '_method');" \
        "m.setAttribute('value', 'delete');" \
        "f.appendChild(m);" \
        "var s = document.createElement('input');" \
        "s.setAttribute('type', 'hidden');" \
        "s.setAttribute('name', 'authenticity_token');" \
        "s.setAttribute('value', '#{form_authenticity_token}');" \
        "f.appendChild(s);" \
        "f.submit();"

      if options[:confirm]
        onclick = "if (confirm('#{options[:confirm]}')) {#{onclick}};"
        options[:confirm] = nil
      end
      options[:onclick] = onclick + "return false;"
    end

    super(*params)
  end

  ## E-mail to entity
  def email_to(addr, text = nil)
    return '' if addr.blank?
    text ||= addr
    addr.gsub!(/@/, '&#64;')
    addr.gsub!(/a/, '&#97;')
    text.gsub!(/@/, '&#64;')
    text.gsub!(/a/, '&#97;')
    mail_to(text, addr)
  end

  ## Tel
  def tel_to(tel, text = nil)
    text ||= tel
    return tel if tel.to_s !~ /^([\(]?)([0-9]+)([-\(\)]?)([0-9]+)([-\)]?)([0-9]+$)/
    link_to text, "tel:#{tel}"
  end

  def header_menu
    menus = [
      {:class=>"home", :url=>"/_admin", :label=>"ホームへもどる"},
      {:class=>"personalProf", :url=>"/_admin/sns/profile_photos", :label=>"個人設定"},
      {:class=>"restriction", :url=>"/_admin/sns/privacies", :label=>"プライバシー設定"},
      {:class=>"sso", :url=>"/_admin/sso?to=gw", :label=>"Joruri Gw へ移動"}
      ]
     menus << {:class=>"manager",:url=>"/_admin/sns/display_items",:label=>"管理者メニュー"} if Core.user.has_auth?(:manager)
     menus << {:class=>"manager",:url=>"/_admin/sys",:label=>"管理画面"} if Core.user.has_auth?(:manager)
     menus << {:class=>"logout", :url=>"/_admin/logout", :label=>"ログアウト"}
     ret = "<ul>"
     menus.each do |m|
       ret += %Q(<li class="#{m[:class]}"><a href="#{m[:url]}">#{m[:label]}</a></li>)
    end
    ret += "</ul>"
    return ret
  end
end