module Sns::Model::File
  def mkdir_for_file(path)
    # 末尾が / ならディレクトリと見なし、存在しないならディレクトリを作成する
    # 末尾が / 以外なら、ファイル名と見なし、そのファイル名を作成するのに必要なディレクトリが存在しないなら作成する
    # 再帰的に必要なだけディレクトリを作成することに注意
    # @return: 作成に成功したら true 失敗したら false
    mode_file = !path.ends_with?('/')
    px = path.split(/\//)
    dir_name = px[0, px.length - (mode_file ? 1 : 0)].join(File::Separator)
    ret = true
    begin
      FileUtils.mkdir_p(dir_name) unless File.exist?(dir_name)
    rescue
      ret = false
    end
    return ret
  end

  def display_file_name
    "#{original_file_name}(#{eng_unit})"
  end

  def escaped_name
    CGI::escape(file_name)
  end

  def eng_unit
    _size = file_size
    return '' unless _size.to_s =~ /^[0-9]+$/
    if _size >= 10**9
      _kilo = 3
      _unit = 'G'
    elsif _size >= 10**6
      _kilo = 2
      _unit = 'M'
    elsif _size >= 10**3
      _kilo = 1
      _unit = 'K'
    else
      _kilo = 0
      _unit = ''
    end

    if _kilo > 0
      _size = (_size.to_f / (1024**_kilo)).to_s + '000'
      _keta = _size.index('.')
      if _keta == 3
        _size = _size.slice(0, 3)
      else
        _size = _size.to_f * (10**(3-_keta))
        _size = _size.to_f.ceil.to_f / (10**(3-_keta))
      end
    end

    "#{_size}#{_unit}Bytes"
  end

end
